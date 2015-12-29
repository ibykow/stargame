if require?
  Util = require './util'
  Sprite = require './sprite'

[ceil, cos, sin] = [ Math.ceil, Math.cos, Math.sin]

(module ? {}).exports = class Bullet extends Sprite
  @SPEED: 10
  constructor: (@gun) ->
    return unless @gun
    super @gun.game, @gun.position.slice(), 2, 2, "#ffd"

    vx = @gun.velocity[0]
    vy = @gun.velocity[1]
    xdir = cos @position[2]
    ydir = sin @position[2]
    xnorm = ceil xdir
    ynorm = ceil ydir
    @velocity = [xdir * Bullet.SPEED, ydir * Bullet.SPEED]
    @position[0] += xdir * (@gun.width + 2)
    @position[1] += ydir * (@gun.height + 2)
    @life = 60 * 1
    @update()
    # console.log 'new bullet at', @position

  updateVelocity: -> # the velocity doesn't change

  update: ->
    super()
    @life--
