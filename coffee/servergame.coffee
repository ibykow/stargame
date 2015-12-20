Util = require './util'
Game = require './game'
Sprite = require './sprite'

(module ? {}).exports = class ServerGame extends Game
  constructor: (server, @width, @height, numStars = 10, @frictionRate) ->
    return unless server
    super @width, @height, @frictionRate
    @server = server
    @sprites = @generateStars(numStars)
    @initStates = @getStarStates()

  generateStars: (n) ->
    for i in [0..n]
      width = Util.randomInt(5, 20)
      height = Util.randomInt(5, 20)
      new Sprite(@, width, height)

  getStarStates: ->
    for star in @sprites
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

      # if player.clientState
      #   console.log player.clientState.position[0], player.ship.position[0],
      #               player.clientState.position[1], player.ship.position[1],
      #               player.clientState.position[2], player.ship.position[2],
      #               synced

      player.clientState = null

    states

  prepareInputs: ->
    for player in @players when player and player.inputs.length
      player.inputs.sort (a, b) -> a.inputSequence - b.inputSequence
      latestPlayer = player.inputs[player.inputs.length - 1]
      player.inputSequence = latestPlayer.inputSequence
      player.clientState = latestPlayer.clientState
      temp = []
      for data in player.inputs
        temp.push data.input

      player.inputs = temp

  update: ->
    @prepareInputs()
    super()

  step: (time) ->
    super time # it's the best kind
    @server.io.emit 'state',
      ships: @generateShipStates()
      tick: @tick
      fromServer: true
