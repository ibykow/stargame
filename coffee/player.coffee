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

  die: ->
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
