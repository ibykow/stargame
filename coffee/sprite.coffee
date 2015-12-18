if require?
  Util = require './util'

(module ? {}).exports = class Sprite
  constructor: (@game, @width = 10, @height = 10, @position, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0, 0]

  updateVelocity: ->
    @velocity[0] *= @game.frictionRate
    @velocity[1] *= @game.frictionRate

  updatePosition: ->
    @position[i] += @velocity[i] for i in [0...@position.length]
    @position[0] = (@position[0] + @game.width) % @game.width
    @position[1] = (@position[1] + @game.height) % @game.height

  update: ->
    @updateVelocity()
    @updatePosition()

  getState: ->
    position: @position
    velocity: @velocity
    width: @width
    height: @height
    color: @color

  draw: ->
    @game.c.fillStyle = @color
    @game.c.fillRect  @position[0] - @width / 2,
                      @position[1] - @height / 2,
                      @width, @height
