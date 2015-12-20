if require?
  Ship = require './ship'

(module ? {}).exports = class Player
  @TURN_RATE: 0.06
  constructor: (@game, @id, @socket) ->
    return null unless @game and @id
    @ship = new Ship(@)
    @inputs = []
    @inputSequence = 0

  actions:
    forward: ->
      @ship.velocity[0] += Math.cos(@ship.position[2])
      @ship.velocity[1] += Math.sin(@ship.position[2])

    reverse: ->
      @ship.velocity[0] -= Math.cos(@ship.position[2])
      @ship.velocity[1] -= Math.sin(@ship.position[2])

    left: ->
      @ship.position[2] -= Player.TURN_RATE

    right: ->
      @ship.position[2] += Player.TURN_RATE

    brake: ->
      @ship.velocity[0] *= Ship.BRAKE_RATE
      @ship.velocity[1] *= Ship.BRAKE_RATE

  update: ->
    @inputs = [@inputs] unless @inputs.length and Array.isArray @inputs[0]

    for input in @inputs
      for act in input when input.length and act?.length
        @actions[act].bind(@)()

      @ship.update()

      # if input.length
        # console.log 'input', input, 'position', @ship.position, 'velocity', @ship.velocity

    @inputs = []
