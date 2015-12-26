if require?
  Sprite = require './sprite'
  Bullet = require './bullet'

# Shorthands for commonly used / long-named functions
[abs, floor, min, max, trunc, cos, sin] = [
  Math.abs,
  Math.floor
  Math.min,
  Math.max,
  Math.trunc,
  Math.cos,
  Math.sin
]

(module ? {}).exports = class Ship extends Sprite
  @RATES:
    ACC: 2
    BRAKE: 0.96
    TURN: 0.06

  @glideBrake: ->
    # glideBrake: A drop-in replacement for the 'brake' instance function.
    # A constant rate of friction means that holding the brake button
    # results in the ship gliding smoothly to a stop.
    # This behavior annoys me to no end, so I opted for the current
    # default found below (aka responsive braking).
    # If you want to play around with this drop it into a ship instance via:
    # `myShip.brake = Ship.glideBrake`
    # or, to change it for all instances:
    # 'Ship::brake = Ship.glideBrake'
    # and of course there's always the copy / paste option.
    return unless @magnitude
    @isBraking = true
    @velocity[0] *= Ship.RATES.BRAKE
    @velocity[1] *= Ship.RATES.BRAKE

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

    @gear = 0
    @flags.isBraking = false

    # TODO create 'ship engine' class around brakePower and accFactor
    # Would allow for engines as upgrades/purchases
    @brakePower = 1000
    @accFactor = Ship.RATES.ACC

  forward: ->
    @velocity[0] += cos(@position[2]) * @accFactor
    @velocity[1] += sin(@position[2]) * @accFactor

  reverse: ->
    @velocity[0] -= cos @position[2]
    @velocity[1] -= sin @position[2]

  left: ->
    @position[2] -= Ship.RATES.TURN

  right: ->
    @position[2] += Ship.RATES.TURN

  brake: ->
    # 'Responsive' / 'variable rate' braking
    # Provides a smooth braking experience that doesn't drag on at the end.
    return unless @magnitude
    @isBraking = true
    rate = min @magnitude * @magnitude / @brakePower, Ship.RATES.BRAKE
    @velocity[0] *= rate
    @velocity[1] *= rate

  fire: ->
    console.log 'firing'
    @game.sprites.push new Bullet(@)

  update: ->
    super()
    @updateCollisions()

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
    @flags.isVisible = true
