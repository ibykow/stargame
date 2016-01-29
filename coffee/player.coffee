if require?
  Config = require './config'
  Benchmark = require './benchmark'
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
    @statsPrintTick = 0

    @generateShip ship
    super @game, @params
    @ship.playerID = @id
    @bench = new Benchmark @

  actions:
    forward: ->
      return unless @ship.fuel > 0
      @ship.fuel -= @ship.accFactor
      @ship.accelerate 'forward',
        [ cos(@ship.rotation) * @ship.accFactor,
          sin(@ship.rotation) * @ship.accFactor, 0 ]

      @emit 'nofuel' if @ship.fuel < 1

    reverse: ->
      return unless @ship.fuel > 0
      @ship.fuel--
      @ship.accelerate 'reverse',
        [ -(cos @ship.rotation),
          -(sin @ship.rotation), 0 ]

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

    fire: -> @ship?.fire()

    stats: ->
      return if @game.tick.count - @statsPrintTick < 60
      @statsPrintTick = @game.tick.count
      @page 'Statistics'
      (@page 'Game ' + s) for s in @game.bench.getStatStrings 'step', 'update'
      (@page 'Player ' + s) for s in @bench.getStatStrings 'update'

    suicide: (mods) ->
      birthDelta = @game.tick.count - @ship.born
      return if @dead or (birthDelta < 50) or ((mods & 3) - 3 < 0)
      console.log '' + @ + ' self destructed ' + @ship
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

  initEventHandler: ->
    super()
    @on 'refuel',(data) =>
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
    @ship?.delete? 'to replace it with a shinier one: ' + state.id
    @ship = Ship.fromState @game, state, view
    @ship.playerID = @id
    @ship.player = @

  processInputs: ->
    {map, modifiers} = @inputs
    @actions[action].call @, modifiers for action in map when action?.length

  updateInputLog: ->
    entry =
      sequence: @inputSequence
      gameStep: @game.tick.count
      serverStep: @game.serverTick.count
      ship: @ship?.getState()
      inputs:
        map: @inputs.map.slice()
        modifiers: @inputs.modifiers
      gasStationIndex: @gasStationIndex

    @logs['input'].insert entry
    @latestInputLogEntry = entry
    @inputSequence++

  update: ->
    @processInputs()
    @ship.update()
    @die() unless @ship.health > 0
