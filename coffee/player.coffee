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

    super @game, @params
    @generateShip ship
    @ship.playerID = @id
    @bench = new Benchmark @

  actions:
    forward: -> @ship.accelerate 1
    reverse: -> @ship.accelerate -0.5

    brake: -> @ship.brake()

    decoy: -> @ship.createDecoy()

    left: -> @ship.turn 'left', -Config.common.ship.rates.turn

    right: -> @ship.turn 'right', Config.common.ship.rates.turn

    fire: -> @ship?.fire()

    # Use for general info
    info: -> console.log Object.keys @game.lib.at 'Star'

    stats: ->
      return if @game.tick.count - @statsPrintTick < 60
      @statsPrintTick = @game.tick.count
      @page 'Statistics'
      (@page 'Game ' + s) for s in @game.bench.getStatStrings 'step', 'update'
      (@page 'Player ' + s) for s in @bench.getStatStrings 'update'

    suicide: (mods) ->
      bits = Config.common.modifiers.bits
      mask = bits.alt | bits.ctrl
      birthDelta = @game.tick.count - @ship.born
      return unless ((mods & mask) is mask) and (birthDelta > 50)
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

  initEventHandler: ->
    super()
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

  generateShip: (state) ->
    @logs['input'].reset()
    @ship?.delete? 'to replace it with a shinier one: ' + state.id
    @ship = Ship.fromState @game, state
    @ship.playerID = @id
    @ship.player = @
    console.log 'Generated ' + @ship + ' for ' + @

  processInputs: (inputs) ->
    {map, modifiers} = inputs
    @actions[action]?.call @, modifiers for action in map

  sendInitialState: ->
    # send the id and game information back to the client
    projectiles = @game.lib.at 'Projectile'
    @socket.emit 'welcome',
      game:
        deadShipIDs: @game.deadShipIDs
        height: @game.height
        width: @game.width
        player: @getState()
        rates: @game.rates
        ships: @game.getShipStates()
        starStates: @game.starStates
        tick: @game.tick
      projectiles:
        dead: []
        new: (p.getState() for id, p of projectiles when not p.deleted)

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
    @ship.accelerating = false
    @processInputs @inputs
    @ship.update()
