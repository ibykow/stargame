if require?
  Sprite = require './sprite'

(module ? {}).exports = class Ship extends Sprite
  @BRAKE_RATE: 0.8
  constructor: (@player) ->
    return null unless @player
    super @player.game
    @gear = 0
    @brake = false

  updateVelocity: ->
    if @brake
      @brake = false
      @velocity[0] *= Ship.BRAKE_RATE
      @velocity[1] *= Ship.BRAKE_RATE
    else if @gear
      @velocity[0] += @gear * Math.cos(@position[2])
      @velocity[1] += @gear * Math.sin(@position[2])

    super()
