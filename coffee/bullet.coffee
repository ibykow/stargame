if require?
  Util = require './util'
  Sprite = require './sprite'

(module ? {}).exports = class Bullet extends Sprite
  @SPEED: 10
  constructor: (@gun) ->
    return unless @gun
    super @gun.game, @gun.position.slice(), 2, 2, "#ffd"
    @velocity = [
      Math.cos(@position[2]) * Bullet.SPEED,
      Math.sin(@position[2]) * Bullet.SPEED
    ]

    @life = 60 * 3

  updateVelocity: -> # the velocity doesn't change

  update: ->
    super()
    @life--
