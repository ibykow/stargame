(module ? {}).exports = class Sprite
  constructor: (@game, @position) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @velocity = [0, 0, 0]

  updateVelocity: ->
    @velocity[0] *= @game.frictionRate
    @velocity[1] *= @game.frictionRate

  updatePosition: ->
    @position[i] += @velocity[i] for i in [0...position.length]

  update: ->
    @updateVelocity()
    @updatePosition()
