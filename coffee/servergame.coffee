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
    for player in @players
      id: player.id
      ship: player.ship.getState()

  update: ->
    super()

  step: (time) ->
    super time # it's the best kind
    @server.io.emit 'state',
      ships: @generateShipStates()
      tick: @tick
