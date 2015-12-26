if require?
  Ship = require './ship'

(module ? {}).exports = class Player
  constructor: (@game, @id, @socket, position) ->
    return null unless @game and @id
    @ship = new Ship(@, position)
    @arrows = []
    @inputs = []
    @inputSequence = 1

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
