if require?
  Config = require './config'
  Util = require './util'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'

isnum = Util.isNumeric
isarr = Array.isArray

(module ? {}).exports = class Emitter
  @events: {}
  @nextID: 1
  @processHandlers: (game, handlers, name, data) ->
    return unless game? and handlers[name]?
    step = game.tick.count
    handlers[name].filter (handler) ->
      return false if handler.deleted
      handler.step.current = step
      result = handler.callback data, handler
      handler.step.previous = step
      handler.deleted = not handler.repeats
      if handler.timer and handler.deleted
        handler.timer.delete()
        handler.timer = null
      return handler.repeats

  @run: (game) ->
    for name, eventsList of @events
      for info in eventsList
        info.target.listeners[name] = @processHandlers game,
          info.target.listeners, name, info.data

        delete @events[name]

  @fromState: (game, state = {}, view) ->
    return unless game

    console.log 'WARNING! Deleted state:', @name, state.id if state.deleted

    emitter = game.lib[@name]?[state.id]

    if emitter
      # Overwrite the type to match the current/real constructor
      state.type = @name
      emitter.setState state
    else
      emitter = new @ game, state
      emitter.insertView?() if view

    for name, child of state.children
      child.parent = emitter
      emitter.children[name] = global[child.type].fromState game, child, view

    emitter

  constructor: (@game, @params = {}) ->
    return unless @game?
    @born = @game.tick.count
    @deleted = @params.deleted or false
    @listeners = {}
    @immediates = {} # immediate listeners
    @children = {}
    @type = @constructor.name
    @game.lib[@type] = {} unless @game.lib[@type]

    if @params.id
      @id = @params.id
      Emitter.nextID = @params.id if @id > Emitter.nextID
    else
      @id = Emitter.nextID

    @game.lib[@type][@id] = @

    {@parent, @alwaysUpdate} = @params
    @parent.adopt @ if @parent?.id

    @game.updatables[@id] = @ if @params.alwaysUpdate

    Emitter.nextID++

    @initEventHandlers()
    @game.emit 'new', @

  initEventHandlers: ->

  # (Re)places child and force updates child's parent
  adopt: (child) ->
    return unless child?.id
    @children[child.id] = child
    return if child.parent is @

    # Take the child away from the its current parent if present
    delete child.parent.children[child.id] if child.parent?
    child.parent = @

  delete: ->
    @emit 'delete', parseInt @id
    if @view?.delete?
      @view.delete()
      @view = null

    @parent = null
    child.delete() for name, child of @children
    @children = {}
    @listeners = {}
    @immediates = {}

    @getState = null
    @deleted = true

    if o = @game.lib[@type]?[@id]
      console.log 'WARNING: id mismatch', @type, @id, o.id unless o is @
      delete @game.lib[@type][@id]

    delete @game.updatables[@id]

  getChildrenMatching: (info) ->
    results = []
    (results.push child if child.matches info) for id, child of @children

    return results

  getState: ->
    states = {}
    states[name] = child.getState() for name, child of @children

    if @parent? then parentState =
      id: @parent.id
      type: @parent.type

    id: @id
    type: @constructor.name
    children: states
    parent: parentState or null
    alwaysUpdate: @alwaysUpdate

  setState: (state, setChildStates = false) ->
    {@id, @type, @alwaysUpdate} = state
    if setChildStates and state.children
      for name, child of @children when state.children[name]?
        child.setState state.children[name], true

  emit: (name, data = {}) -> # Emits an event. TODO: Prevent infinite loops.
    info =
      target: @
      data: data

    # Process immediates
    @immediates[name] = Emitter.processHandlers @game, @immediates, name, data

    if isarr Emitter.events[name] then Emitter.events[name].push info
    else Emitter.events[name] = [info]

  isDeleted: -> @deleted or (@getState is null)

  # Returns whether there's a match between ourselves and the state provided
  # {exact}: Every key of state must exist and equal @[key]
  matches: (state, exact = false) ->
    for key, value of state
      return false unless (@[key] is value) or ((not @[key]?) and not exact)

    return true

  # registers callback to be run as soon as the event is emmited
  now: (name, handler, timeout, repeats) ->
    @on name, handler, timeout, repeats, true

  # registers an event listener
  on: (name, handler, timeout = 0, repeats = true, now = false) ->
    return if @isDeleted()
    step = @game.tick.count
    switch typeof handler
      when 'object'
        return unless cb = handler.callback

        if handler.bind?.length then handler.callback = cb.bind handler.bind...

        now = handler.immediate or handler.now or now
        handler.repeats ?= repeats
        handler.deleted ||= false
        handler.timedOut ||= false
        handler.timer ||= null
        handler.step ||=
          start: step
          current: step
          previous: step

      when 'function'
        callback = handler
        handler =
          repeats: repeats
          callback: callback
          deleted: false
          timedOut: false
          timer: null
          step:
            start: step
            current: step
            previous: step

      else return

    handler.name = name

    if timeout > 0
      timercb = (handler, timer) ->
        handler.timedOut = true
        handler.callback handler

      handler.timer = new Timer step, timeout, timercb.bind @, handler

    if now then type = 'immediates' else type = 'listeners'
    if isarr @[type][name] then @[type][name].push handler
    else @[type][name] = [handler]

    return handler

  once: (name, handler, timeout) -> @on name, handler, timeout, false, false
  onceNow: (name, handler, timeout) -> @now name, handler, timeout, false
  update: -> child.update() for type, child of @children

  insertView: -> # do nothing
