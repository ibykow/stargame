if require?
  Sprite = require './sprite'

(module ? {}).exports = class Ship extends Sprite
  @BRAKE_RATE: 0.8
  @draw: (c, position, color) ->
    return unless c and position and color

    c.save()
    c.fillStyle = color
    c.translate position...
    c.rotate position[2]
    c.globalAlpha = 1
    c.beginPath()
    c.moveTo 10, 0
    c.lineTo -10, 5
    c.lineTo -10, -5
    c.closePath()
    c.fill()
    c.restore()

  constructor: (@player) ->
    return null unless @player
    super @player.game
    @gear = 0
    @brake = false

  draw: ->
    c = @player.game.c
    Ship.draw(c, @position, @color)
