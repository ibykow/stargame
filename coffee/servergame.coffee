Config = require './config'
Util = require './util'
Server = require './server'
Game = require './game'
Player = require './player'
Sprite = require './sprite'

# Sprite::updateView gets called during the update stage, so
# there's not a nicer way of ignoring its functionality without
# subclassing into ClientSprite or breaking apart Sprite::update.
# Another way is to have a conditional at the top of the function
# which checks and exits if we're on the server. However, running
# a conditional every time seems like overkill.
Sprite::updateView = ->

Player::updateInputLog = ->
  if @inputs.length
    console.log 'input', @inputSequence, @ship.position, @inputs
  @inputs = []

(module ? {}).exports = class ServerGame extends Game
  constructor: (server, @width, @height, numStars = 10, @frictionRate) ->
    return unless server
    super @width, @height, @frictionRate

    @server = server
    @stars = @generateStars(numStars)
    @starStates = @getStarStates()
    @newBullets = []

    # On the server-side, players keep only the inputs necessary to do updates.
    Player.LOGLEN = Config.server.updatesPerStep + 10

  insertBullet: (b) ->
    return unless b
    super()
    @newBullets.push b

  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      new Sprite(@, null, width, height)

  getStarStates: ->
    for star in @stars
      position: star.position
      width: star.width
      height: star.height
      color: star.color

  getShipStates: ->
    for player in @players
      id: player.id
      inputSequence: player.inputSequence
      ship: player.ship.getState()

  sendState: ->
    shipStates = @getShipStates()
    bulletStates = (bullet.getState() for bullet in @newBullets)
    @server.io.emit 'state',
      ships: shipStates
      bullets: bulletStates
      tick: @tick

  update: ->
    @newBullets = []
    for i in [1..Config.server.updatesPerStep]
      super()
      # player updates can remove themselves from the players list
      # to avoid problems, we iterate over a copy of the players list
      players = @players.slice()
      for player in players
        player.inputs = player.logs['input'].remove() or []
        player.update()

      if players.length is not @players.length
        console.log 'Had', players.length, 'players. Now', @players.length

    @sendState()
