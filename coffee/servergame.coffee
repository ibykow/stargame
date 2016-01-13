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

    {stars} = @params
    @generateStars stars

    @starStates = (star.getState() for id, star of @lib['Star'])
    @page = console.log
    @newBullets = []

  insertBullet: (bullet) -> @newBullets.push bullet if bullet?

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
      state = player.getState()
      # Reset ship
      player.ship.damaged = 0
      player.ship.firing = false
      state

    if initial then lib = @lib['Bullet'] or {} else lib = @newBullets
    bullets = (bullet.getState() for bullet in lib when not bullet.isDeleted())

    players: players
    bullets: bullets

  sendInitialState: (player) ->
    return unless player
    {players, bullets} = @getStates 'initial'

    # send the id and game information back to the client
    player.socket.emit 'welcome',
      bullets:
        dead: []
        new: bullets
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
    {players, bullets} = @getStates()

    @server.io.emit 'state',
      bullets:
        dead: @deadBulletIDs
        new: bullets
      game:
        deadShipIDs: @deadShipIDs
        tick: @tick
      players: players

  update: -> super() for [1..conf.updatesPerStep]

  step: (time) ->
    super time
    @sendState()
    @deadBulletIDs = []
    @deadShipIDs = []
    @newBullets = []
