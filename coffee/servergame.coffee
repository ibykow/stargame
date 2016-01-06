if require?
  Config = require './config'
  Util = require './util'
  Eventable = require './eventable'
  Server = require './server'
  Game = require './game'
  Player = require './player'
  Star = require './star'
  GasStation = require './gasstation'
  Market = require './market'

conf = Config.server
# On the server-side, players keep only the inputs necessary to do updates.
Player.LOGLEN = conf.updatesPerStep + 1

{abs, floor, sqrt, round, trunc} = Math
isarr = Array.isArray
rnd = Math.random

(module ? {}).exports = class ServerGame extends Game
  constructor: (@server, @params) ->
    return unless @server?
    super @params

    {stars} = @params
    @generateStars stars

    @starStates = (star.getState() for id, star of @lib['Star'])
    @page = console.log
    @newBullets = []
    @deadBulletIDs = []

  insertBullet: (bullet) -> @newBullets.push bullet if bullet?

  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      star = new Star @, null, width, height
      if rnd() < Config.common.rates.gasStation
        new GasStation star
      if rnd() < Config.common.rates.market
        new Market star

  sendInitialState: (player) ->
    return unless player

    playerStates = (player.getState() for id, player of @lib['Player'])
    bulletStates = (bullet.getState() for bullet in @lib['Bullet']?)

    # send the id and game information back to the client
    player.socket.emit 'welcome',
      bullets:
        dead: []
        new: bulletStates
      ships: playerStates
      game:
        player: player.getState()
        width: @width
        height: @height
        rates: @rates
        tick: @tick
        starStates: @starStates

  sendState: ->
    playerStates = (player.getState() for id, player of @lib['Player'])
    bulletStates = (bullet.getState() for bullet in @newBullets)

    @server.io.emit 'state',
      bullets:
        dead: @deadBulletIDs
        new: bulletStates
      ships: playerStates
      game:
        tick: @tick

  # update each bullet state and remove dead bullets
  updateCollisions: ->
    # @bullets = @bullets.filter (b) =>
    #   for type, sprites of @collisionSpriteLists
    #     sprite.handleBulletImpact b for sprite in b.detectCollisions sprites
    return unless bullets = @lib['Bullet']
    collidableTypes = conf.bulletCollidableTypes
    for id, bullet of bullets
      if bullet.life <= 0
        bullet.delete()
        @deadBulletIDs.push id
        continue

      # primitive, and inefficient collision detection
      # TODO: Add a quadtree implementation to handle big sets.
      for type in collidableTypes when @lib[type]?
        for id, model of @lib[type]
          if bullet.intersects model
            @emit 'hit',
              bullet: bullet
              model: model
            bullet.delete()
            @deadBulletIDs.push id

  update: ->
    for i in [conf.updatesPerStep..1]
      super()
      # @updateCollisions()

  step: (time) ->
    super time
    @sendState()
    @deadBulletIDs = []
    @newBullets = []
