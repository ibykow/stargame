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
  constructor: (@game, @socket, position) ->
    super @game # initialize eventable
    @ship = new Ship @, position
    @arrows = []
    @inputs = []
    @cash = 3000
    @minInputSequence = 1 # used by the server
    @inputSequence = 1
    @logs =
      state: new RingBuffer Player.LOGLEN
      input: new RingBuffer Player.LOGLEN

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
        return @game.page "Gas station", @gasStationIndex,
          "is out of order. Sorry."

      # Avoid filter cheating by requiring player-station proximity
      if @ship.distanceTo(station) > Config.common.fuel.distance
        return @game.page 'Sorry. The gas station is too far away.'

      # No money :(
      return @game.page "Sorry, you're broke." unless @cash > 0

      # Calculate the fuel and cost
      fuelDelta = @ship.fuelCapacity - @ship.fuel

      return @game.page "You're full!" unless fuelDelta > 0

      price = fuelDelta * station.fuelPrice

      # Buy as much as we can afford
      if price > @cash
        fuelDelta = @cash / station.fuelPrice
        price = @cash

      # Transact
      @cash -= price
      @ship.fuel += fuelDelta

      # Emit
      @emit 'refuel',
        station: station
        delta: fuelDelta
        price: price

  registerEventHandlers: ->
    @ship.on 'nofuel', (data) => console.log 'no fuel', data, @
    @ship.onceOn 'accelerate', (data) => console.log 'first flight', data, @
    @ship.onceOn 'turn', (data) =>
      console.log 'turning', data.direction, data, @
    @ship.on 'refuel', ((data) ->
      {station, delta, price} = data
      info = 'You bought ' + delta.toFixed(2) + 'L of fuel for ' +
        pesoChar + price.toFixed(2) + ' at ' + pesoChar +
        station.fuelPrice.toFixed(2) + '/L';
      @game.page info).bind @


  arrowTo: (sprite, id, color = '#00F') ->
    @arrows.push(new Arrow @game, @ship, sprite, color, 0.8, 2, id)

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

  updateArrows: ->
    arrows = @arrows.slice()
    for arrow, i in arrows
      if arrow.b.flags.isDeleted
        @arrows.splice i, 1
      else
        arrow.update()

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
