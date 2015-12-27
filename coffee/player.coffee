if require?
  RingBuffer = require './ringbuffer'
  Ship = require './ship'

(module ? {}).exports = class Player
  @LOG_LEN: 1 << 8 # over 4s worth of frames at 60fps
  constructor: (@game, @id, @socket, position) ->
    return null unless @game and @id
    @ship = new Ship(@, position)
    @arrows = []
    @inputs = []
    @inputSequence = 1
    @logs =
      input: new RingBuffer Player.LOG_LEN
      state: new RingBuffer Player.LOG_LEN

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

  updateArrows: -> arrow.update() for arrow in @arrows

  update: ->
    for action in @inputs when action?.length
      @actions[action].bind(@)()

    @inputs = []
    @ship.update()
    @updateArrows()
