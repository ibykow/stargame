if require?
  Sprite = require './sprite'

(module ? {}).exports = class Ship extends Sprite
  @BRAKE_RATE: 0.94
  @DEFAULT_ACC_FACTOR: 2
  @TURN_RATE: 0.06
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
    super @player.game, @position, 20, 20
    @accFactor = Ship.DEFAULT_ACC_FACTOR
    @gear = 0

  forward: ->
    @velocity[0] += Math.cos(@position[2]) * @accFactor
    @velocity[1] += Math.sin(@position[2]) * @accFactor

  reverse: ->
    @velocity[0] -= Math.cos @position[2]
    @velocity[1] -= Math.sin @position[2]

  left: ->
    @position[2] -= Ship.TURN_RATE

  right: ->
    @position[2] += Ship.TURN_RATE

  brake: ->
    @velocity[0] *= Ship.BRAKE_RATE
    @velocity[1] *= Ship.BRAKE_RATE

  update: ->
    super()
    @updateCollided()

  draw: ->
    Ship.draw(@player.game.c, @view, @color)

  @drawMaster: ->
    Ship.draw(@player.game.c,
      [ @game.canvas.halfWidth + @velocity[0],
        @game.canvas.halfHeight + @velocity[1],
        @position[2]], @color)

  @updateViewMaster: ->
    @view = [@game.canvas.halfWidth + @velocity[0],
      @game.canvas.halfHeight + @velocity[1],
      @position[2]]

    @game.viewOffset = [@position[0] - @game.canvas.halfWidth,
                        @position[1] - @game.canvas.halfHeight]
    @visible = true
