if require?
  Util = require './util'
  Sprite = require './ship'

(module ? {}).exports = class InterpolatedShip extends Ship
  constructor: (@player, state) ->
    return null unless @player and state.position
    super @player, state.position
    @velocity = state.velocity
    @color = state.color
    @prev = state
    @next = state

  updateVelocity: ->
  updatePosition: ->
    rate = @game.interpolation.rate * @game.interpolation.step
    @position = Util.lerp(@prev.position, @next.position, rate)

  setState: (state) ->
    @prev =
      position: @next.position
      width: @next.velocity
      height: @next.height
      color: @next.color
    @next = state
