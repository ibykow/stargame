if require?
  Config = require './config'
  Util = require './util'
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

    if emitter = game.lib[type]?[state.id] then emitter.setState state
    else emitter = new @ game, state

    for name, child of state.children
      child.parent = emitter
      emitter.children[name] = global[child.type].fromState game, child

    return emitter

  constructor: (@game, @params = {}) ->
    return unless @game?
    {@parent, @type} = @params

    @born = @game.tick.count
    @children = {}
    @deleted = @params.deleted or false
    @immediates = {} # immediate listeners
    @isEmitter = true
    @listeners = {}
    @page = @game.page
    @type ?= @constructor.name

    @game.lib[@type] = {} unless @game.lib[@type]

    if @params.id
      @id = @params.id
      Emitter.ids[@type] = @id if @id > Emitter.ids[@type]
    else
      Emitter.ids[@type] ?= 0
      Emitter.ids[@type]++
      @id = Emitter.ids[@type]

    @game.lib[@type][@id] = @
    @parent.adopt @ if @parent?.id

    @initHandlers()
    @game.emit 'new', @

  # (Re)places child and force updates child's parent
  adopt: (child) ->
    return unless child?.id
    @children[child.id] = child
    return if child.parent is @

    # Take the child away from its current parent if present
    delete child.parent.children[child.id] if child.parent?
    child.parent = @

  delete: (reason = 'for no particular reason') ->
    @deleted = true
    # console.log 'Deleting ' + @ + ' ' + reason

    @emit 'delete', parseInt @id

    @parent = null
    child.delete 'because its parent is ' + @ for name, child of @children

    @children = {}
    @listeners = {}
    @immediates = {}

    @getState = null

    delete @game.lib[@type]?[@id]

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

    if setChildStates and state.children
      for name, child of @children when state.children[name]?
        child.setState state.children[name], true

  toString: -> '' + this.type + ' ' + this.id
  update: -> child.update() for type, child of @children
