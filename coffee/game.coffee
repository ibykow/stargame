if require?
  Config = require './config'
  Benchmark = require './benchmark'
  Util = require './util'
  Olib = require './olib'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'
  Emitter = require './emitter'
  Model = require './model'
  Physical = require './physical'
  Explosion = require './explosion'
  Player = require './player'

{min, max, sqrt} = Math
isarr = Array.isArray
isnum = Util.isNumeric
lg = console.log.bind console

Model::explode = (state = position: @position.slice()) ->
  new Explosion @game, state
  @delete 'because it exploded'

Physical::explode = ->
  super
    position: @position.slice()
    velocity: @velocity.slice()

(module ? {}).exports = class Game extends Emitter
  constructor: (@params) ->
    {@width, @height, @rates} = @params
    @size = sqrt @width**2 + @height**2
    Emitter.bench = new Benchmark Emitter
    @deadProjectileIDs = []
    @deadShipIDs = []
    @partitions = (({} for [0...@rates.partition]) for [0...@rates.partition])
    @partitionSize = @width / @rates.partition
    @toroidalLimit = [@width, @height]
    @paused = true
    @lib = new Olib() # keep references of all emitters in existence

    @tick =
      count: @params.tick?.count or 0
      time: 0
      dt: 0

    @types = update: []

    # Emitter expects an initialized game
    super @, @params
    @bench = new Benchmark @
    console.log 'Created game ' + @id

  around: (partition = [0, 0]) ->
    if isnum arguments[1]
      radius = arguments[1]
      type = arguments[2]
    else
      radius = arguments[2]
      type = arguments[1]

    return @at partition, type unless radius > 1

    results = []
    parts = @rates.partition
    for i in [-radius...radius]
      for j in [-radius...radius]
        x = (partition[0] + i + parts) % parts
        y = (partition[1] + j + parts) % parts
        results = results.concat @at [x, y], type

    results

  at: (partition, type) ->
    return [] unless partition?.length is 2

    results = []
    if type
      models = @partitions[partition[0]][partition[1]][type] or {}
      results.push model for id, model of models

    else
      for type, models of @partitions[partition[0]][partition[1]]
        results.push model for id, model of models
    return results

  framesToMs: (frames) -> frames * Config.common.msPerFrame
  msToFrames: (ms) -> ms / Config.common.msPerFrame
  randomPosition: -> [Util.randomInt(0, @width), Util.randomInt(0, @height)]

  getTypeMatching: (type, info) ->
    if typeof info is 'function' then callback = info
    else callback = (e) -> e.matches info

    results = []
    lib = @lib[type] or {}
    @lib.each type, (emitter) -> results.push emitter if callback emitter
    return results

  getAllMatching: (info) ->
    results = []
    (results = results.concat @getTypeMatching type, info) for type of @lib
    return results

  logPlayerStates: ->
    for player in @players when player
      player.logs['state'].insert
        sequence: @tick.count
        id: player.id
        ship: player.ship.getState()

  step: (time) ->
    @tick.dt = time - @tick.time
    @tick.time = time
    @update()

  update: ->
    step = @tick.count++
    Timer.run step # Timer loop
    Emitter.run @ # Event loop
    (@lib.each type, (e) -> e.update()) for type in @types.update
