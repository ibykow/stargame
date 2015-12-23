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

  constructor: (@player, @position) ->
    return null unless @player
    @gear = 0
    @width = 20
    @height = 20
    @brake = false
    super @player.game, @position

  draw: ->
    Ship.draw(@player.game.c, @view, @color)

  updateViewMaster: ->
    @view = [
      @game.canvas.halfWidth,
      @game.canvas.halfHeight,
      @position[2]
    ]

    @game.viewOffset = [
      @position[0] - @game.canvas.halfWidth,
      @position[1] - @game.canvas.halfHeight
    ]

    @visible = true
