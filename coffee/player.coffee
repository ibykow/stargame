if require?
  Ship = require './ship'

(module ? {}).exports = class Player
  constructor: (@game, @id, @socket, position) ->
    return null unless @game and @id
    @ship = new Ship(@, position)
    @arrows = []
    @inputs = []
    @inputSequence = 0

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

  updateArrows: ->
    arrow.update() for arrow in @arrows

  update: ->
    @inputs = [@inputs] unless @inputs.length and Array.isArray @inputs[0]

    for input in @inputs
      for act in input when input.length and act?.length
        @actions[act].bind(@)()

      @ship.update()

    @inputs = []

    @updateArrows()
