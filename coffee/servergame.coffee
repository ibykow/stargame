Util = require './util'
Game = require './game'
Sprite = require './sprite'

(module ? {}).exports = class ServerGame extends Game
  constructor: (server, @width, @height, numStars = 10, @frictionRate) ->
    return unless server
    super @width, @height, @frictionRate
    @server = server
    @sprites = @generateStars(numStars)
    @states = @getStarStates()

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
    for player in @players when player
      id: player.id
      ship: player.ship.getState()

  preparePlayerInputs: ->
    for player in @players when player
      if player.input and player.input.length
        player.input.sort (a, b) -> a.tick.count - b.tick.count
        player.input = player.input.reduce ((p, n) -> p.concat n.input), []

  update: ->
    @preparePlayerInputs()
    super()

  step: (time) ->
    super time # it's the best kind
    shipStates = @generateShipStates()
    @server.io.emit 'state',
      ships: shipStates
      tick: @tick
