if require?
  Config = require './config'
  Util = require './util'
  Timer = require './timer'
  RingBuffer = require './ringbuffer'
  Eventable = require './eventable'
  Player = require './player'

(module ? {}).exports = class Game extends Eventable
  constructor: (@params) ->
    {@width, @height, @rates} = @params
    @toroidalLimit = [@width, @height]
    @paused = true
    @events ||= {}
    @lib ||= {} # keep references of all eventables in existence
    @tick =
      count: @params.count or 0
      time: 0
      dt: 0

    # Eventable expects an initialized game
    super @, @params

    @initializeEventHandlers()

  framesToMs: (frames) -> frames * Config.common.msPerFrame
  msToFrames: (ms) -> ms / Config.common.msPerFrame
  randomPosition: -> [Util.randomInt(0, @width), Util.randomInt(0, @height), 0]

  initializeEventHandlers: ->
    for name, handlers of @events
      for info in handlers
        info.callback = info.callback.bind @
        @on name, info

  insertBullet: (bullet) -> # do nothing client-side

  update: ->
    step = @tick.count++
    Timer.run step
    Eventable.run @
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
