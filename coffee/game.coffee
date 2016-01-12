if require?
  Config = require './config'
  Util = require './util'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'
  Emitter = require './emitter'
  Player = require './player'

isarr = Array.isArray

(module ? {}).exports = class Game extends Emitter
  constructor: (@params) ->
    {@width, @height, @rates} = @params
    @deadBulletIDs = []
    @deadShipIDs = []
    @partitions = (({} for [0...@rates.partition]) for [0...@rates.partition])
    @partitionSize = @width / @rates.partition
    @toroidalLimit = [@width, @height]
    @paused = true
    @events ||= {}
    @lib ||= {} # keep references of all emitters in existence
    @tick =
      count: @params.count or 0
      time: 0
      dt: 0

    # Emitter expects an initialized game
    super @, @params

  around: (partition = [0, 0], radius = 1) ->
    return @at partition if radius < 1
    limit = radius * 2 + 1
    parts = @rates.partition
    results = {}
    [x, y] = [(partition[0] - radius) + parts, (partition[1] - radius) + parts]

    for [0...limit]
      x = (x + 1) % parts
      for [0...limit]
        y = (y + 1) % parts
        results = Object.assign results, @at [x, y]

    results

  at: (partition) -> @partitions[partition[0]][partition[1]] if isarr partition
  each: (type, cb) -> cb value for name, value of @lib[type] or {}
  framesToMs: (frames) -> frames * Config.common.msPerFrame
  msToFrames: (ms) -> ms / Config.common.msPerFrame
  randomPosition: -> [Util.randomInt(0, @width), Util.randomInt(0, @height), 0]

  initEventHandlers: ->
    super()
    for name, handlers of @events
      for info in handlers
        info.callback = info.callback.bind @
        @on name, info

  insertBullet: (bullet) -> # do nothing client-side

  update: ->
    step = @tick.count++
    Timer.run step
    Emitter.run @
    bullet.update() for id, bullet of @lib['Bullet'] or {}

  logPlayerStates: ->
    for player in @players when player
      player.logs['state'].insert
        sequence: @tick.count
        id: player.id
        ship: player.ship.getState()

  step: (time) ->
    # increment the tick
    @tick.dt = time - @tick.time
    @tick.time = time
    @update()
