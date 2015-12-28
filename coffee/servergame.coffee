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

(module ? {}).exports = class ServerGame extends Game
  constructor: (server, @width, @height, numStars = 10, @frictionRate) ->
    return unless server
    super @width, @height, @frictionRate

    @server = server
    @stars = @generateStars(numStars)
    @starStates = @getStarStates()

    # On the server-side, players keep only the inputs necessary to do updates.
    Player.LOGLEN = Server.FRAMES_PER_STEP

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
    bulletStates = (bullet.getState() for bullet in @bullets)
    @server.io.emit 'state',
      ships: shipStates
      bullets: bulletStates
      tick: @tick

  update: ->
    for i in [1..Config.server.framesPerStep]
      super()
      for player in @players
        player.inputs = player.logs['input'].remove() or []
        player.update()

    @sendState()
