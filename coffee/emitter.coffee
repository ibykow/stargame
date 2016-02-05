if require?
  Config = require './config'
  Util = require './util'
  Olib = require './olib'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'

isnum = Util.isNumeric
isarr = Array.isArray

{max, min} = Math

(module ? {}).exports = class Emitter
  @events = {}
  @ids: {}
  @run: (game) ->
    for name, event of @events
      for info in event
        info.target.processHandlers 'listeners', name, info.data
      delete @events[name]

  @fromState: (game, state = {}) ->
    return unless game

    # Overwrite the type to match the current/real constructor
    type = @name

    console.log 'WARNING! Deleted state:', type, state.id if state.deleted

    if emitter = game.lib.get type, state.id then emitter.setState state
    else emitter = new @ game, state

    for type, data of state.children
      for id, state of data
        state.parent = emitter
        global[state.type].fromState game, state

    return emitter

  constructor: (@game, @params = {}) ->
    return unless @game?
    {@parent, @type} = @params

    @born = @game.tick.count
    @children = new Olib()
    @deleted = @params.deleted or false
    @immediates = {} # immediate listeners
    @isEmitter = true
    @listeners = {}
    @page = @game.page
    @type ?= @constructor.name

    @id = @params.id if @params.id
    @game.lib.put @

    @parent.adopt @ if @parent?.id

    @initHandlers()
    @game.emit 'new', @

  # (Re)places child and force updates child's parent
  adopt: (child) ->
    return unless child
    child.parent?.remove? child
    @children.put child
    child.parent = @

  delete: (reason = 'for no particular reason') ->
    @deleted = true
    # console.log 'Deleting ' + @ + ' ' + reason

    @emit 'delete',
      id: parseInt @id
      type: @type.slice()

    @parent.children.remove @ if @parent and not @parent.deleted
    @parent = null

    @children.each (child) => child.delete 'because its parent is ' + @

    @children = {}
    @listeners = {}
    @immediates = {}
    @getState = null
    @game.lib.remove @

  emit: (name, data = {}) -> # Emits an event. TODO: Prevent infinite loops.
    info =
      target: @
      data: data

    # Process immediates
    if @immediates[name]?.length
      handlers = @immediates[name]
      @immediates[name] = @processHandlers 'immediates', name, data

    if isarr Emitter.events[name] then Emitter.events[name].push info
    else Emitter.events[name] = [info]

  equals: (emitter) -> @id is emitter.id and (@type is emitter.type)

  getChildrenMatching: (info) ->
    (@children.filter (child) -> child.matches info) if info

  getState: ->
    childStates = @children.map (child) -> child.getState()

    if @parent then parentState =
      id: @parent.id
      type: @parent.type

    id: @id
    type: @constructor.name
    children: childStates
    parent: parentState or null

  initHandlers: ->

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

        if bindings = handler.bindings
          bindings = [bindings] unless isarr bindings
          handler.callback = cb.bind bindings...

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
    handler.target = @

    if timeout > 0
      timercb = (handler, timer) ->
        handler.timedOut = true
        handler.callback handler

      handler.timer = new Timer timeout, timercb.bind @, handler

    if now then type = 'immediates' else type = 'listeners'
    if isarr @[type][name] then @[type][name].push handler
    else @[type][name] = [handler]

    return handler

  once: (name, handler, timeout) -> @on name, handler, timeout, false

  processHandlers: (handlerType, name, data) ->
    return unless handlers = @[handlerType]?[name]
    step = @game.tick.count
    @[handlerType][name] = handlers.filter (handler) ->
      return false if handler.deleted
      handler.step.current = step
      result = handler.callback data, handler
      handler.step.previous = step
      handler.deleted = not handler.repeats
      if handler.timer and handler.deleted
        handler.timer.delete()
        handler.timer = null
      handler.repeats

  setState: (state, setChildStates = false) ->
    {@id, @type} = state

    return unless setChildStates and state.children
    for type, dict of @children
      for id, childState of dict
        child.setState childState, true if child = @children.get state

  toString: -> '' + this.type + ' ' + this.id
  update: -> @children.each (child) -> child.update()
