if require?
  Config = require './config'
  Util = require './util'
  RingBuffer = require './ringbuffer'
  Ship = require './ship'

pesoChar = Config.common.chars.peso

(module ? {}).exports = class Player
  @LOGLEN: Config.client.player.loglen
  constructor: (@game, @id, @socket, position) ->
    return null unless @game
    @ship = new Ship(@, position)
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
      @ship.forward()

    reverse: ->
      @ship.reverse()

    left: ->
      @ship.left()

    right: ->
      @ship.right()

    brake: ->
      @ship.brake()

    fire: ->
      @ship.fire()

    refuel: ->
      # There must be a valid gas station for this to work
      return unless Util.isNumeric @game.gasStationID
      station = @game.stars[@game.gasStationID].children['GasStation']
      return @game.page "Gas station out of order. Sorry." unless station

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

      # Inform
      info = 'You bought ' + fuelDelta.toFixed(2) + 'L of fuel for ' +
        pesoChar + price.toFixed(2) + ' at ' + pesoChar +
        station.fuelPrice.toFixed(2) + '/L'

      @game.page info

  die: ->
    console.log "I'm dead", @id
    @socket.disconnect()

  arrowTo: (sprite, id, color = '#00F') ->
    @arrows.push(new Arrow @game, @ship, sprite, color, 0.8, 2, id)

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
      gasStationID: @game.gasStationID

    @logs['input'].insert entry
    # console.log 'new entry', entry.sequence, entry.ship.position

    @latestInputLogEntry = entry
    @inputSequence++

  update: ->
    for action in @inputs when action?.length
      @actions[action].bind(@)()

    @ship.update()
    @die() if @ship.health < 0
