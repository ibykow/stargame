if require?
  Sprite = require './sprite'

(module ? {}).exports = class Ship extends Sprite
  constructor: (@player) ->
    return null unless @player
    super @player.game
    @gear = 0

  updateVelocity: ->
    if @gear
      @velocity[0] += @gear * Math.cos(@position[2])
      @velocity[1] += @gear * Math.sin(@position[2])

    super()
