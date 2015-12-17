if require?
  Sprite = require './sprite'

(module ? {}).exports = class Ship extends Sprite
  @BRAKE_RATE: 0.8
  constructor: (@player) ->
    return null unless @player
    super @player.game
    @gear = 0
    @brake = false

  updateVelocity: ->
    if @brake
      @velocity[0] *= Ship.BRAKE_RATE
      @velocity[1] *= Ship.BRAKE_RATE
      @brake = false
    else if @gear
      @velocity[0] += @gear * Math.cos(@position[2])
      @velocity[1] += @gear * Math.sin(@position[2])
      @gear = 0

    super()

  draw: ->
    c = @player.game.c

    c.save()
    c.fillStyle = @color
    c.translate @position...
    c.rotate @position[2]
    c.globalAlpha = 1
    c.beginPath()
    c.moveTo 10, 0
    c.lineTo -10, 5
    c.lineTo -10, -5
    c.closePath()
    c.fill()
    c.restore()
