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
  @conf: Config.common.ship
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
    @decoys = []
    @fireRate = rates.fire
    @firing = false
    @gear = 0
    @health = 100
    @lastFired = 0
    @maxHealth = 100

    # how many input sequences to skip before next fire

    # TODO create 'ship engine' class around brakePower and accelerationFactor
    # Would allow for engines as upgrades/purchases
    @brakePower = 550
    @accelerationFactor = rates.acceleration

    @fuelCapacity = 10000
    @fuel = parseInt @fuelCapacity
    super @game, @params

  createDecoy: -> @page 'Creating decoy'

  initHandlers: ->
    super()
    @on 'nofuel', (data) => console.log 'Player', @id, 'ran out of fuel'

    # Holographs don't do collision detection
    @now 'hit', (model) => @health -= model.damage or 0 unless @holographic

  accelerate: (amount = 1) ->
    return unless @fuel > 0
    @accelerating = true
    @gear = amount

    rate = @accelerationFactor * amount

    x = rate * cos @rotation
    y = rate * sin @rotation

    @velocity[0] += x
    @velocity[1] += y

    @emit 'acceleration',
      amount: amount
      rate: rate
      vector: [x, y]

    @fuel -= abs rate
    @emit 'nofuel' unless @fuel > 0

  brake: ->
    return unless @magnitude
    @accelerating = true
    @gear = 0
    rate = Ship.conf.rates.brake
    rate = min(@magnitude * @magnitude / @brakePower, rate) - 1

    x = @velocity[0] * rate
    y = @velocity[1] * rate
    @velocity[0] += x
    @velocity[1] += y

    @emit 'brake',
      rate: rate
      vector: [x, y]

  delete: ->
    @player?.ship = null
    super arguments[0]

  die: ->
    return if @dead
    console.log 'deleting ship ' + @id
    @dead = true
    @game.deadShipIDs.push @id
    player = @player
    @explode()
    @emit 'death'
    player?.emit 'lost ship'

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
      amount: amount
      direction: direction

  update: ->
    super()
    @die() unless @health > 0

  insertView: ->
    @view = new ShipView @game, model: @
    @view.update = ->
      {halfWidth, halfHeight} = @game.canvas
      v = @model.velocity

      @offset = [halfWidth + v[0], halfHeight + v[1]]
      @rotation = @model.rotation
      @visible = true
      @game.visibleViews.push @
