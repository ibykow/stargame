if require?
  Config = require './config'
  Physical = require './physical'
  ShipView = require './shipview'
  Projectile = require './projectile'

# Shorthands for commonly used / long-named functions
{abs, floor, min, max, trunc, cos, sin} = Math
isarr = Array.isArray
rates = Config.common.ship.rates
lg = console.log.bind console

(module ? {}).exports = class Ship extends Physical
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
    @braking = true
    @velocity[0] *= shipRate.brake
    @velocity[1] *= rates.brake

  constructor: (@game, @params) ->
    return unless @game?
    @braking = false
    @fireRate = rates.fire
    @firing = false
    @gear = 0
    @health = 100
    @lastFired = 0
    @maxHealth = 100

    # how many input sequences to skip before next fire

    # TODO create 'ship engine' class around brakePower and accFactor
    # Would allow for engines as upgrades/purchases
    @brakePower = 550
    @accFactor = rates.acceleration

    @fuelCapacity = 1000
    @fuel = parseInt @fuelCapacity
    super @game, @params

  initHandlers: ->
    @now 'hit': (model) => @health -= model.damage or 0
    @on 'nofuel', (data) => console.log 'Player', @id, 'ran out of fuel'
    super()

  accelerate: (direction, vector) ->
    return unless isarr vector
    @velocity[0] += vector[0]
    @velocity[1] += vector[1]
    @emit 'accelerate',
      direction: direction
      vector: vector

  delete: ->
    @player?.ship = null
    super arguments[0]

  fire: -> @emit 'fire'

  getState: ->
    Object.assign super(),
      fireRate: @fireRate
      firing: @firing
      fuel: @fuel
      fuelCapacity: @fuelCapacity
      health: @health
      lastFired: @lastFired
      playerID: @playerID

  setState: (state) ->
    super state
    {@firing, @fireRate, @fuel, @fuelCapacity,
      @health, @lastFired, @playerID} = state

  turn: (direction, amount) ->
    @rotation += amount
    @emit 'turn',
      direction: direction
      amount: amount

  insertView: ->
    @view = new ShipView @game, model: @
    @view.update = ->
      {halfWidth, halfHeight} = @game.canvas
      v = @model.velocity

      @offset = [halfWidth + v[0], halfHeight + v[1]]
      @rotation = @model.rotation
      @visible = true
      @game.visibleViews.push @
