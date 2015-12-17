if require?
  Sprite = require './game'

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    { @width, @height, @frictionRate, @tick } = details.game

    super @width, @height, @frictionRate

    @player = new Player(@, details.player.id, socket)
    @player.name = 'Guest'
    @players = [@player]

  update: ->
    super()
    @draw()

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  draw: ->
    @clear()
    player.ship.draw() for player in @players
