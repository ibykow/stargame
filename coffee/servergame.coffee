Util = require './util'
Game = require './game'
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
    @initStates = @getStarStates()

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

  generateShipStates: ->
    states = []
    for player in @players when player
      synced = not player.clientState or
        (player.clientState.position[0] == player.ship.position[0]) and
        (player.clientState.position[1] == player.ship.position[1]) and
        (player.clientState.position[2] == player.ship.position[2])
      states.push
        id: player.id
        inputSequence: player.inputSequence
        ship: player.ship.getState()
        synced: synced

      player.clientState = null

    states

  prepareInputs: ->
    for player in @players when player and player.inputs.length
      player.inputs.sort (a, b) -> a.inputSequence - b.inputSequence
      newestData = player.inputs[player.inputs.length - 1]
      player.inputSequence = newestData.inputSequence
      player.clientState = newestData.clientState
      player.inputs = (data.input for data in player.inputs)

  update: ->
    # @prepareInputs()
    super()
    super()
    super()
    super()
    super()

  step: (time) ->
    super time # it's the best kind
    @server.io.emit 'state',
      ships: @generateShipStates()
      tick: @tick
      fromServer: true
