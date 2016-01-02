if require?
  Config = require './config'
  Util = require './util'

(module ? {}).exports = class Eventable
  @nextID: 1
  @registry: [] # list of existing eventables

  constructor: (@game) ->
    return unless @game
    @listeners = {}
    @id = Eventable.nextID
    @registryIndex = (Eventable.registry.push @) - 1
    Eventable.nextID++

  getState: -> id: @id

  setState: (state) -> @id = state.id ? @id

  delete: -> # delete events and listeners, and remove self from registry
    @events = null
    @listeners = null
    Eventable.registry.splice @registryIndex, 1

  emit: (name, data) -> # Emits an event. TODO: Prevent infinite loops.
    return unless @listeners[name]?.length
    data.tick = @game.tick.count
    callback data for callback in @listeners[name]

  on: (name, callback) -> # registers an event listener
    @listeners[name] = @listeners[name] ? []
    @listeners[name].push callback

  removeListener: (name, callback) -> # removes the callback from listeners
    return unless Array.isArray @listeners[name]
    index = @listeners[name].indexOf callback
    @listeners[name].splice i, 1 if ~index

  removeListeners: (name) ->
    callbacks = @listeners[name]
    @listeners[name] = []
    callbacks
