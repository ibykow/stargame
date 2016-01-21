if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'
  RingBuffer = require './ringbuffer'
  Ship = require './ship'

{cos, max, min, sin} = Math

pesoChar = Config.common.chars.peso

(module ? {}).exports = class Player extends Emitter
  @LOGLEN: Config.client.player.loglen
  constructor: (@game, @params) ->
    {@socket, ship} = @params
    @inputs = []
    @cash = 3000
    @minInputSequence = 1 # used by the server
    @inputSequence = 1
    @logs =
      state: new RingBuffer Player.LOGLEN
      input: new RingBuffer Player.LOGLEN
    @generateShip ship
    super @game, @params
    @ship.playerID = @id

  actions:
    forward: ->
      return unless @ship.fuel > 0
      @ship.fuel -= @ship.accFactor
      @ship.accelerate 'forward',
        [ cos(@ship.position[2]) * @ship.accFactor,
          sin(@ship.position[2]) * @ship.accFactor, 0 ]

      @emit 'nofuel' if @ship.fuel < 1

    reverse: ->
      return unless @ship.fuel > 0
      @ship.fuel--
      @ship.accelerate 'reverse',
        [ -(cos @ship.position[2]),
          -(sin @ship.position[2]), 0 ]

      @emit 'nofuel' if @ship.fuel < 1

    brake: ->
      magnitude = @ship.magnitude
      return unless magnitude
      @ship.braking = true
      rate = Config.common.ship.rates.brake
      rate = (min magnitude * magnitude / @ship.brakePower, rate) - 1
      @ship.accelerate 'brake',
        [ @ship.velocity[0] * rate,
          @ship.velocity[1] * rate, 0]

    left: -> @ship.turn 'left', -Config.common.ship.rates.turn
    right: -> @ship.turn 'right', Config.common.ship.rates.turn

    fire: -> @ship.fire()

    suicide: ->
      return if @dead or (@game.tick.count - @ship.born < 50)
      console.log 'Player', @id, 'has commited suicide', @ship.id
      @ship.health = 0

    refuel: ->
      unless station = @game.gasStations[@gasStationIndex]
        return @emit 'refuel-error',
          index: @gasStationIndex
          type: '404'

      # No money :(
      unless @cash > 0
        return @emit 'refuel-error',
          index: @gasStationIndex
          type: 'nsf'

      # Calculate the fuel and cost
      fuelDelta = @ship.fuelCapacity - @ship.fuel

      unless fuelDelta > 0
        return @emit 'refuel-error',
          index: @gasStationIndex
          type: 'full'

      # Avoid filter cheating by requiring player-station proximity
      distance = @ship.distanceTo station
      if distance > Config.common.fuel.distance
        return @emit 'refuel-error',
          index: @gasStationIndex
          type: 'distance'
          distance:
            required: Config.common.fuel.distance
            actual: distance

      price = fuelDelta * station.fuelPrice

      # Buy only as much as we can afford
      if price > @cash
        fuelDelta = @cash / station.fuelPrice
        price = @cash

      # Transact
      @cash -= price
      @ship.fuel += fuelDelta

      # Emit
      @emit 'refuel',
        index: @gasStationIndex
        delta: fuelDelta
        price: price

  die: ->
    return if @dead
    @dead = true
    @game.deadShipIDs.push @ship.id
    @ship.explode()
    @emit 'die'

  initEventHandlers: ->
    @ship.on 'nofuel', (data) => console.log 'Player', @id, 'ran out of fuel'

    @on 'refuel', (data) =>
      {index, delta, price} = data
      console.log 'Gas station', index, 'sold', delta.toFixed(2) +
      'L of fuel to player', @id

  getState: ->
    Object.assign super(),
      inputSequence: @inputSequence
      ship: @ship?.getState()

  setState: (state) ->
    super state
    @inputSequence = state.inputSequence
    @ship.setState state.ship

  generateShip: (state, view) ->
    @logs['input'].reset()
    @ship?.delete?()
    @ship = Ship.fromState @game, state, view
    @ship.playerID = @id
    @ship.player = @

  updateInputLog: ->
    entry =
      sequence: @inputSequence
      gameStep: @game.tick.count
      serverStep: @game.serverTick.count
      ship: @ship?.getState()
      inputs: @inputs.slice()
      gasStationIndex: @gasStationIndex

    @logs['input'].insert entry
    @latestInputLogEntry = entry
    @inputSequence++

  update: ->
    @actions[action].bind(@)() for action in @inputs when action?.length
    @ship.update()
    @die() unless @ship.health > 0
