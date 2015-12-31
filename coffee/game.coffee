if require?
  Util = require './util'
  Player = require './player'

(module ? {}).exports = class Game
  constructor: (@width = 1 << 8, @height = 1 << 8, @frictionRate = 0.96) ->
    @toroidalLimit = [@width, @height]
    @players = []
    @ships = []
    @stars = []
    @bullets = []
    @paused = true
    @viewOffset = [0, 0] # used by sprites
    @collisionSpriteLists =
      stars: @stars
      ships: @ships
    @tick =
      count: 0
      time: 0
      dt: 0

  framesToMs: (frames) ->
    frames * Config.common.msPerFrame

  msToFrames: (ms) ->
    ms / Config.common.msPerFrame

  randomPosition: ->
    [Util.randomInt(0, @width), Util.randomInt(0, @height), 0]

  removePlayer: (p) ->
    return unless p
    for i in [0...@players.length]
      if @players[i].id is p.id
        @players.splice(i, 1)
        break

  insertBullet: (b) ->
    return unless b
    @bullets.push b

  getShips: ->
    @players.map((p)-> p.ship)

  updateBullets: ->
    # update each bullet state and remove dead bullets
    bullets = []
    for b in @bullets
      b.update()
      for type, spirte of @collisionSpriteLists
        for sprite in b.detectCollisions sprite
          sprite.handleBulletImpact b

      if b.life > 0
        bullets.push b

    # update bullet list to include only live ones
    @bullets = bullets

  update: ->
    @tick.count++
    @updateBullets()

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
