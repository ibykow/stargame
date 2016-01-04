if require?
  Config = require './config'
  Util = require './util'
  Time = require './timer'
  RingBuffer = require './ringbuffer'

isnum = Util.isNumber

(module ? {}).exports = class Eventable
  @nextID: 1
  @log: new RingBuffer Config.common.events.log.max
  constructor: (@game) ->
    return unless @game
    @listeners = {}
    @id = Eventable.nextID
    Eventable.nextID++
    @game.emit 'new', @

  getState: -> id: @id
  setState: (state) -> @id = state.id ? @id

  emit: (name, data = {}) -> # Emits an event. TODO: Prevent infinite loops.
    listeners = @listeners[name]
    return unless listeners?.length

    entries = []

    step = @game.tick.count

    listeners = listeners.filter (callback) ->
      # filter out previously removed callbacks right away
      return false if callback.remove
      data.step = callback.step
      result = callback data
      callback.step.previous = step
      callback.remove = callback.once or (callback.conditional and not result)

      entries.push
        callback: callback
        removed: callback.remove
        result: result

      # if .remove is false, we return true to filter out the callback
      return callback.remove is false

    Eventable.log.insert
      step: step
      id: @id
      name: name
      data: data
      handlers: entries

  # registers an event listener
  on: (name, callback, once = false, conditional = false) ->
    @listeners[name] = @listeners[name] ? []

    callback.step =
      first: @game.tick.count
      previous: @game.tick.count

    callback.once = once
    callback.conditional = conditional
    @listeners[name].push callback

  onUntil: (name, callback, expireStep, failcb) ->
    return unless name and callback and failcb
    step = @game.tick.count
    period = (max 0, exprieStep - step) + 1

    success = (timer, data) ->
      callback data
      timer.delete()

    failure = (name, callback) =>
      failcb name, callback
      @removeListener name, callback

    timer = new Timer step - 1, period, failure, false, @, [name, callback]
    success.bind @, timer
    @on name, success


  onceOn: (name, callback) -> @on name, callback, true
  conditionalOn: (name, callback) -> @on name, callback, false, true
  removeListener: (name, callback) -> callback.remove = true
  removeListeners: (name) -> @listeners[name] = []
