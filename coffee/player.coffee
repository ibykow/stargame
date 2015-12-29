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

  update: ->
    return @die() if @ship?.health < 1

    for action in @inputs when action?.length
      @actions[action].bind(@)()

    @inputs = []
    @ship.update()
