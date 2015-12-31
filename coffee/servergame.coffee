Config = require './config'
Util = require './util'
Server = require './server'
Game = require './game'
Player = require './player'
Sprite = require './sprite'
GasStation = require './gasstation'

# Sprite::updateView gets called during the update stage, so
# there's not a nicer way of ignoring its functionality without
# subclassing into ClientSprite or breaking apart Sprite::update.
# Another way is to have a conditional at the top of the function
# which checks and exits if we're on the server. However, running
# a conditional every time seems like overkill.
Sprite::updateView = ->

# Player::updateInputLog = ->
  # if @inputs.length
    # console.log 'updated ship', @inputSequence, @ship.position, @inputs

# On the server-side, players keep only the inputs necessary to do updates.
Player.LOGLEN = Config.server.updatesPerStep + 1

[abs, floor, isarr, sqrt, rnd, round, trunc] = [Math.abs, Math.floor,
  Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc]

(module ? {}).exports = class ServerGame extends Game
  constructor: (server, @width, @height, numStars = 10, @frictionRate) ->
    return unless server
    super @width, @height, @frictionRate

    @server = server
    @stars = @generateStars numStars
    @starStates = (star.getState() for star in @stars)
    @page = -> # do nothing

  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      star = new Sprite(@, null, width, height)
      star.id = i
      # console.log 'star', star
      new GasStation star if rnd() < Config.common.rates.gasStations
      star

  getShipStates: ->
    for player in @players
      shipState = player.ship.getState()
      # console.log 'sending', player.inputSequence, shipState.position
      id: player.id
      inputSequence: player.inputSequence
      ship: shipState

  sendState: ->
    shipStates = @getShipStates()
    bulletStates = (bullet.getState() for bullet in @bullets)
    @server.io.emit 'state',
      ships: shipStates
      bullets: bulletStates
      tick: @tick

  update: ->
    for i in [1..Config.server.updatesPerStep]
      # Player updates can remove players from the list.
      # To avoid problems, we iterate over a copy of @players.
      super()
      players = @players.slice()
      for player in players
        logEntry = player.logs['input'].remove()
        player.inputs = logEntry?.inputs or []
        player.update()
        player.die() unless player.ship.health > 0
        # console.log 'updated player', player.id, logEntry?.sequence,
        #   logEntry?.inputs, player.inputSequence, player.ship.position

      if players.length is not @players.length
        console.log 'Had', players.length, 'players. Now', @players.length

    @sendState()
