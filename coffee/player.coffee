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
    # console.log 'latest', @latestInputLogEntry?.sequence,
      # @latestInputLogEntry?.ship.position
    entry =
      sequence: @inputSequence
      ship: @ship.getState()
      inputs: @inputs.slice()

    @logs['input'].insert entry
    # console.log 'new entry', entry.sequence, entry.ship.position

    @latestInputLogEntry = entry
    @inputSequence++

  update: ->
    for action in @inputs when action?.length
      @actions[action].bind(@)()

    @ship.update()
    @inputs = []
