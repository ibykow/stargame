if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'
  Server = require './server'
  Game = require './game'
  Player = require './player'
  Ship = require './ship'
  DecoyShip = require './decoyship'
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

Ship::createDecoy = ->
  @decoys.push new DecoyShip @game, Object.assign @getState(), source: @

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

    @starStates = @lib.each 'Star', (star) -> star.getState()
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

  getShipStates: ->
    @lib.each 'Ship', (ship) ->
      return if ship.deleted
      state = Object.assign ship.getState(),
        inputSequence: ship.player?.inputSequence
      ship.damaged = 0
      ship.firing = false
      return state

  sendState: ->
    @server.io.emit 'state',
      game:
        deadShipIDs: @deadShipIDs
        ships: @getShipStates()
        tick: @tick
      projectiles:
        dead: @deadProjectileIDs
        new: (p.getState() for id, p of @newProjectiles when not p.deleted)

  update: -> super() for [1..conf.updatesPerStep]

  step: (time) ->
    super time
    @sendState()
    @deadProjectileIDs = []
    @deadShipIDs = []
    @newProjectiles = {}
