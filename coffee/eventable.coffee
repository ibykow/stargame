if require?
  Config = require './config'
  Util = require './util'

(module ? {}).exports = class Eventable
  @nextID: 1
  constructor: (@game) ->
    return unless @game
    @listeners = {}
    @id = Eventable.nextID
    Eventable.nextID++

  getState: -> id: @id
  setState: (state) -> @id = state.id ? @id

  emit: (name, data) -> # Emits an event. TODO: Prevent infinite loops.
    listeners = @listeners[name]
    return unless listeners?.length

    for callback in listeners when not callback.remove
      data.step = callback.step
      passed = callback data
      data.step.previous = @game.tick.count
      callback.remove = callback.once or (callback.conditional and not passed)

    # Filter out removed callbacks
    listeners = listeners.filter (callback) -> not callback.remove

  # registers an event listener
  on: (name, callback, once = false, conditional = false) ->
    @listeners[name] = @listeners[name] ? []

    callback.step =
      first: @game.tick.count
      previous: @game.tick.count

    callback.once = once
    callback.conditional = conditional
    @listeners[name].push callback

  onceOn: (name, callback) -> @on name, callback, true
  conditionalOn: (name, callback) -> @on name, callback, false, true
  removeListener: (name, callback) -> callback.remove = true
  removeListeners: (name) -> @listeners[name] = []
