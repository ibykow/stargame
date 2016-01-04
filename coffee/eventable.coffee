if require?
  Config = require './config'
  Util = require './util'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'

isnum = Util.isNumeric
isarr = Array.isArray

(module ? {}).exports = class Eventable
  @nextID: 1
  @log: new RingBuffer Config.common.events.log.max
  @events: {}
  @run: (step) ->
    deleted = []
    for name, eventsList of @events
      for info in eventsList
        listeners = info.target.listeners[name] or []
        listeners = listeners.filter (handler) ->
          return false if handler.deleted
          handler.step.current = step
          result = handler.callback info.data, handler
          handler.step.previous = step
          handler.deleted = not handler.repeats
          if handler.timer and handler.deleted
            handler.timer.delete()
            handler.timer = null
          return handler.repeats
        deleted.push name
      delete @events[name] for name in deleted

  constructor: (@game) ->
    return unless @game
    @listeners = {}
    @id = Eventable.nextID
    Eventable.nextID++
    @game.emit 'new', @

  getState: -> id: @id
  setState: (state) -> @id = state.id ? @id

  emit: (name, data = {}) -> # Emits an event. TODO: Prevent infinite loops.
    info =
      target: @
      data: data

    if isarr Eventable.events[name]
      Eventable.events[name].push info
    else
      Eventable.events[name] = [info]

  # registers an event listener
  on: (name, callback, timeout = 0, repeats = false) ->
    step = @game.tick.count
    handler =
      target: @
      repeats: repeats
      callback: callback
      deleted: false
      timedOut: false
      timer: null
      step:
        start: step
        current: step
        previous: step

    if timeout > 0
      timercb = (handler, timer) ->
        handler.timedOut = true
        handler.callback handler

      handler.timer = new Timer step, timeout, timercb.bind @, handler

    if isarr @listeners[name]
      @listeners[name].push handler
    else
      @listeners[name] = [handler]
