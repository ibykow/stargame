if require?
  Config = require './config'
  RingBuffer = require './ringbuffer'
  Ship = require './ship'

(module ? {}).exports = class Player
  @LOGLEN: Config.client.player.loglen
  constructor: (@game, @id, @socket, position) ->
    return null unless @game
    @ship = new Ship(@, position)
    @arrows = []
    @inputs = []
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

  die: ->
    @socket.disconnect()

  updateArrows: -> arrow.update() for arrow in @arrows

  updateInputLog: ->
    if @inputs.length
      console.log 'latest', @latestInputLogEntry?.sequence,
        @latestInputLogEntry?.ship.position

    entry =
      sequence: @inputSequence
      ship: @ship.getState()
      inputs: @inputs.slice()

    @logs['input'].insert entry
    console.log entry.ship.position if entry.inputs.length
    @latestInputLogEntry = entry
    @inputs = []
    @inputSequence++

  update: ->
    return @die() if @ship?.health < 1

    for action in @inputs when action?.length
      @actions[action].bind(@)()

    @ship.update()
    @updateInputLog()
