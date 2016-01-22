if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'
  Server = require './server'
  Game = require './game'
  Player = require './player'
  Star = require './star'
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
    super @params

    @types.update = ['Projectile', 'Explosion']

    {stars} = @params
    @generateStars stars

    @starStates = (star.getState() for id, star of @lib['Star'])
    @page = console.log
    @newProjectiles = []

  insertProjectile: (p) -> @newProjectiles.push p if p?

  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      star = new Star @, null, width, height
      for name, rate of conf.starKid.rates when rnd() < rate
        continue unless kidClass = starKidClasses[name]
        new kidClass @, parent: star

  getStates: (initial) ->
    players = for id, player of @lib['Player']
      player.dead = false
      state = player.getState()
      # Reset ship
      player.ship.damaged = 0
      player.ship.firing = false
      state

    if initial then lib = @lib['Projectile'] or {} else lib = @newProjectiles
    projectiles = (projectile.getState() for projectile in lib when not projectile.isDeleted())

    players: players
    projectiles: projectiles

  sendInitialState: (player) ->
    return unless player
    {players, projectiles} = @getStates 'initial'

    # send the id and game information back to the client
    player.socket.emit 'welcome',
      projectiles:
        dead: []
        new: projectiles
      game:
        deadShipIDs: []
        height: @height
        width: @width
        player: player.getState()
        rates: @rates
        starStates: @starStates
        tick: @tick
      players: players

  sendState: ->
    {players, projectiles} = @getStates()

    @server.io.emit 'state',
      projectiles:
        dead: @deadProjectileIDs
        new: projectiles
      game:
        deadShipIDs: @deadShipIDs
        tick: @tick
      players: players

  update: -> super() for [1..conf.updatesPerStep]

  step: (time) ->
    super time
    @sendState()
    @deadProjectileIDs = []
    @deadShipIDs = []
    @newProjectiles = []
