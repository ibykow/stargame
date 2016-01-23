if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'
  Server = require './server'
  Game = require './game'
  Player = require './player'
  Star = require './star'
  Projectile = require './projectile'
  Market = require './market'
  GasStation = require './gasstation'

starKidClasses =
  Market: Market
  GasStation: GasStation

conf = Config.server
# On the server-side, players keep only the inputs necessary to do updates.
Player.LOGLEN = conf.updatesPerStep + 1

{abs, floor, sqrt, round, trunc} = Math
isarr = Array.isArray
rnd = Math.random

(module ? {}).exports = class ServerGame extends Game
  constructor: (@server, @params) ->
    return unless @server?
    @page = console.log.bind console
    super @params

    @types.update = ['Projectile', 'Explosion']

    {stars} = @params
    @generateStars stars

    @starStates = (star.getState() for id, star of @lib['Star'])
    @newProjectiles = {}

  initHandlers: ->
    @on 'new', (model) ->
      switch model.type
        when 'Ship'
          model.on 'fire',
            bindings: [model]
            callback: ->
              return unless @lastFired < @player.inputSequence - @fireRate
              @lastFired = @player.inputSequence
              @firing = true
              projectile = new Projectile @game, shipID: @id
              @game.newProjectiles[projectile.id] = projectile


  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      star = new Star @, null, width, height
      for name, rate of conf.starKid.rates when rnd() < rate
        continue unless kidClass = starKidClasses[name]
        new kidClass @, parent: star

  getPlayerStates: ->
    for id, player of @lib['Player']
      player.dead = false
      state = player.getState()
      # Reset ship
      player.ship.damaged = 0
      player.ship.firing = false
      state

  sendInitialState: (player) ->
    return unless player
    # send the id and game information back to the client
    player.socket.emit 'welcome',
      projectiles:
        dead: []
        new: (p.getState() for id, p of @lib['Projectile'] when not p.deleted)
      game:
        deadShipIDs: []
        height: @height
        width: @width
        player: player.getState()
        rates: @rates
        starStates: @starStates
        tick: @tick
      players: @getPlayerStates()

  sendState: ->
    @server.io.emit 'state',
      projectiles:
        dead: @deadProjectileIDs
        new: (p.getState() for id, p of @newProjectiles when not p.deleted)
      game:
        deadShipIDs: @deadShipIDs
        tick: @tick
      players: @getPlayerStates()

  update: -> super() for [1..conf.updatesPerStep]

  step: (time) ->
    super time
    @sendState()
    @deadProjectileIDs = []
    @deadShipIDs = []
    @newProjectiles = {}
