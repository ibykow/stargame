if require?
  Config = require './config'
  Util = require './util'
  Eventable = require './eventable'
  RingBuffer = require './ringbuffer'
  Ship = require './ship'

{cos, max, min, sin} = Math

pesoChar = Config.common.chars.peso

(module ? {}).exports = class Player extends Eventable
  @LOGLEN: Config.client.player.loglen
  constructor: (@game, @params) ->
    {@socket, ship} = @params
    @ship = new Ship @game, ship
    @inputs = []
    @cash = 3000
    @minInputSequence = 1 # used by the server
    @inputSequence = 1
    @logs =
      state: new RingBuffer Player.LOGLEN
      input: new RingBuffer Player.LOGLEN
    super @game, @params # initialize eventable
    @ship.playerID = @id
    @ship.player = @
    @registerEventHandlers()

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
      @ship.isBraking = true
      rate = Config.common.ship.rates.brake
      rate = (min magnitude * magnitude / @ship.brakePower, rate) - 1
      @ship.accelerate 'brake',
        [ @ship.velocity[0] * rate,
          @ship.velocity[1] * rate, 0]

    left: -> @ship.turn 'left', -Config.common.ship.rates.turn
    right: -> @ship.turn 'right', Config.common.ship.rates.turn

    fire: -> @ship.fire()

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

  registerEventHandlers: ->
    @ship.on 'nofuel', (data) => console.log 'Player', @id, 'ran out of fuel'

    @on 'refuel', (data) =>
      {index, delta, price} = data
      console.log 'Gas station', index, 'sold', delta.toFixed(2) +
      'L of fuel to player', @id

  arrowTo: (view, color, lineWidth, alpha) ->
    params =
      a: @ship.view
      b: view
      color: color
      alpha: alpha
      lineWidth: lineWidth

    new Arrow @game, params

  getState: ->
    Object.assign super(),
      inputSequence: @inputSequence
      ship: @ship.getState()

  setState: (state) ->
    super state
    @inputSequence = state.inputSequence
    @ship.setState state.ship

  die: ->
    console.log "I'm dead", @id
    @socket.disconnect()

  updateInputLog: ->
    entry =
      sequence: @inputSequence
      gameStep: @game.tick.count
      serverStep: @game.serverTick.count
      ship: @ship.getState()
      inputs: @inputs.slice()
      gasStationIndex: @gasStationIndex

    @logs['input'].insert entry
    # console.log 'new entry', entry.sequence, entry.ship.position

    @latestInputLogEntry = entry
    @inputSequence++

  update: ->
    @actions[action].bind(@)() for action in @inputs when action?.length
    @ship.update()
    @die() if @ship.health < 0
