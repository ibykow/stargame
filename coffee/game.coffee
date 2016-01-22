if require?
  Config = require './config'
  Util = require './util'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'
  Emitter = require './emitter'
  Model = require './model'
  Physical = require './physical'
  Explosion = require './explosion'
  Player = require './player'

{min, max} = Math
isarr = Array.isArray
isnum = Util.isNumeric

Model::explode = (state = position: @position.slice()) ->
  new Explosion @game, state
  @page 'Exploding' + @
  @delete 'because it exploded'

Physical::explode = ->
  super
    position: @position.slice()
    velocity: @velocity.slice()

(module ? {}).exports = class Game extends Emitter
  constructor: (@params) ->
    {@width, @height, @rates} = @params
    @deadProjectileIDs = []
    @deadShipIDs = []
    @partitions = (({} for [0...@rates.partition]) for [0...@rates.partition])
    @partitionSize = @width / @rates.partition
    @toroidalLimit = [@width, @height]
    @paused = true
    @events ||= {}
    @lib ||= {} # keep references of all emitters in existence

    @tick =
      count: @params.tick?.count or 0
      time: 0
      dt: 0

    @stats =
      dt:
        last: 0
        average: 0
        min: 10
        max: 0

    @types = update: []

    # Emitter expects an initialized game
    super @, @params

  around: (partition = [0, 0], radius = 1) ->
    return @at partition if radius < 1

    parts = @rates.partition
    results = []

    for x in [-radius...radius]
      for y in [-radius...radius]
        results = results.concat @at [(partition[0] - x + parts) % parts,
          (partition[1] - y + parts) % parts]

    results

  at: (partition) ->
    return [] unless partition?.length is 2
    model for id, model of @partitions[partition[0]][partition[1]]

  each: (type, cb) -> cb value for name, value of @lib[type] or {}
  framesToMs: (frames) -> frames * Config.common.msPerFrame
  msToFrames: (ms) -> ms / Config.common.msPerFrame
  randomPosition: -> [Util.randomInt(0, @width), Util.randomInt(0, @height)]

  getTypeMatching: (type, info) ->
    if typeof info is 'function' then callback = info
    else callback = (e) -> e.matches info

    results = []
    lib = @lib[type] or {}
    @each type, (emitter) -> results.push emitter if callback emitter
    return results

  getAllMatching: (info) ->
    results = []
    (results = results.concat @getTypeMatching type, info) for type of @lib
    return results

  initEventHandlers: ->
    super()
    for name, handlers of @events
      for info in handlers
        info.callback = info.callback.bind @
        @on name, info

  insertProjectile: (projectile) -> # do nothing client-side

  logPlayerStates: ->
    for player in @players when player
      player.logs['state'].insert
        sequence: @tick.count
        id: player.id
        ship: player.ship.getState()

  processStats: ->
    @stats.dt.average = @stats.dt.average * 0.9 + @stats.dt.last * 0.1

    showStats = @game.tick.count % (60 * 5) is 0

    if @stats.dt.last < @stats.dt.min
      @stats.dt.min = @stats.dt.last
      showStats = true

    if @stats.dt.last > @stats.dt.max
      @stats.dt.max = @stats.dt.last
      showStats = true

    return unless showStats

    console.log 'Update ∆t ' + @game.tick.count + ' ' + @stats.dt.last + ' ' +
      @stats.dt.average.toFixed(4) + ' ' + @stats.dt.max

  step: (time) ->
    @tick.dt = time - @tick.time
    @tick.time = time

    @stats.dt.last = +new Date
    @update()
    @stats.dt.last = (+new Date) - @stats.dt.last
    @processStats()

  update: ->
    step = @tick.count++
    Timer.run step # Timer loop
    Emitter.run @ # Event loop
    (@each type, (e) -> e.update()) for type in @types.update # Updates
