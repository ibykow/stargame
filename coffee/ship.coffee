if require?
  Config = require './config'
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

shipRates = Config.common.ship.rates

(module ? {}).exports = class Ship extends Sprite
  @glideBrake: ->
    # glideBrake: A drop-in replacement for the 'brake' instance function.
    # A constant rate of friction means that holding the brake button
    # results in the ship gliding smoothly to a stop.
    # This behavior annoys me to no end, so I opted for the current
    # default found below (aka responsive braking).
    # If you want to play around with this, replace the Ship's brake function
    # before you create any server-side ship instances:
    # 'Ship::brake = Ship.glideBrake'
    return unless @magnitude
    @isBraking = true
    @velocity[0] *= shipRate.brake
    @velocity[1] *= shipRates.brake

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
    super @player.game, @position, 10, 10

    @health = 100
    @maxHealth = 100
    @gear = 0
    @flags.isBraking = false
    @lastFireInputSequence = 0

    # how many input sequences to skip before next fire
    @fireRate = shipRates.fire

    # TODO create 'ship engine' class around brakePower and accFactor
    # Would allow for engines as upgrades/purchases
    @brakePower = 550
    @accFactor = shipRates.acceleration

    @fuel = 1000
    @fuelCapacity = 1000

  forward: ->
    return unless @fuel > 0
    # @velocity[0] += floor cos(@position[2]) * @accFactor
    # @velocity[1] += floor sin(@position[2]) * @accFactor
    @velocity[0] += cos(@position[2]) * @accFactor
    @velocity[1] += sin(@position[2]) * @accFactor
    @fuel -= @accFactor

  reverse: ->
    return unless @fuel > 0
    # @velocity[0] -= floor(cos @position[2])
    # @velocity[1] -= floor(sin @position[2])
    @velocity[0] -= cos @position[2]
    @velocity[1] -= sin @position[2]
    @fuel--

  left: ->
    @position[2] -= shipRates.turn

  right: ->
    @position[2] += shipRates.turn

  brake: ->
    # 'Responsive' / 'variable rate' braking
    # Provides a smooth braking experience that doesn't drag on at the end.
    return unless @magnitude
    @isBraking = true
    rate = min @magnitude * @magnitude / @brakePower, shipRates.brake
    @velocity[0] = @velocity[0] * rate
    @velocity[1] = @velocity[1] * rate

  fire: ->
    return unless @lastFireInputSequence < @player.inputSequence - @fireRate
    @lastFireInputSequence = @player.inputSequence
    @game.insertBullet(new Bullet @)

  handleBulletImpact: (b) ->
    @health -= b.damage
    super b

  getState: ->
    Object.assign super(),
      health: @health
      lastFireInputSequence: @lastFireInputSequence
      fireRate: @fireRate
      fuel: @fuel
      fuelCapacity: @fuelCapacity

  setState: (s) ->
    super(s)
    {@health, @lastFireInputSequence, @fireRate, @fuel, @fuelCapacity} = s

  drawFuel: (x, y) ->
    c = @game.c
    if @fuel
      c.font = "10px Helvetica"
      remain = @fuel / @fuelCapacity
      rate = floor remain * 0xD0
      c.fillStyle = "rgba(" + (0xFF - rate) + "," + rate + "," + 0 + ",1)"
      c.fillRect x, y, floor(remain * 60), 16
      c.fillStyle = "#fff"
      c.fillText 'FUEL', x + 17, y + 12
    else
      c.font = "Bold 10px Helvetica"
      c.fillStyle = "#f00"
      c.fillText 'EMPTY', x + 12, y + 12

    c.strokeStyle = "#fff"
    c.lineWidth = 2
    c.strokeRect x, y, 60, 16

  drawHealth: (x, y) ->
    c = @game.c
    if @health > 0
      remain = @health / @maxHealth
      rate = floor remain * 0xD0
      c.fillStyle = "rgba(" + (0xFF - rate) + "," + rate + "," + 0 + ",1)"
      c.fillRect x, y, floor(remain * 60), 16
      c.fillStyle = "#fff"
      c.font = "10px Helvetica"
      c.fillText 'HEALTH', x + 10, y + 12
    else
      c.font = "Bold 10px Helvetica"
      c.fillStyle = "#f00"
      c.fillText 'DEAD', x + 16, y + 12

    c.strokeStyle = "#fff"
    c.lineWidth = 2
    c.strokeRect x, y, 60, 16

  drawHUD: (x = 260, y = 2) ->
    @drawHealth x, y
    @drawFuel x, y + 20

  draw: ->
    Ship.draw(@player.game.c, @view, @color)

  updateViewMaster: ->
    [x, y, r, vx, vy, halfw, halfh] =
      [ @position[0], @position[1], @position[2],
        @velocity[0], @velocity[1],
        @game.canvas.halfWidth, @game.canvas.halfHeight ]

    @view = [halfw + vx, halfh + vy, r]
    # @game.viewOffset = [x - vx - halfw, y - vy - halfh]
    @game.viewOffset = [x - halfw, y - halfh]

    # The current player's ship is always visible
    @flags.isVisible = true
