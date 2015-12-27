if require?
  Util = require './util'
  Sprite = require './sprite'

[cos, sin] = [Math.cos, Math.sin]

(module ? {}).exports = class Bullet extends Sprite
  @SPEED: 10
  constructor: (@gun) ->
    return unless @gun
    super @gun.game, @gun.position.slice(), 2, 2, "#ffd"

    xdir = cos @position[2]
    ydir = sin @position[2]
    @velocity = [xdir * Bullet.SPEED, ydir * Bullet.SPEED]
    @position[0] += xdir * (@gun.width + 2)
    @position[1] += ydir * (@gun.height + 2)

    @life = 60 * 3

  updateVelocity: -> # the velocity doesn't change

  update: ->
    super()
    @life--
