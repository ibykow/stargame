if require?
  Config = require './config'
  Util = require './util'
  Sprite = require './sprite'

{ceil, cos, sin} = Math
{speed, life} = Config.common.bullet

nextBulletID = 1

(module ? {}).exports = class Bullet extends Sprite
  @fromState: (game, state) ->
    return unless game and state
    state.gun.game = game
    b = new Bullet state.gun
    b.setState state
    b

  constructor: (@gun, @damage = 2) ->
    return unless @gun
    super @gun.game, @gun.position.slice(), 2, 2, "#ffd"

    vx = @gun.velocity[0]
    vy = @gun.velocity[1]
    xdir = cos @position[2]
    ydir = sin @position[2]
    xnorm = ceil xdir
    ynorm = ceil ydir
    @velocity = [xdir * speed, ydir * speed]
    @position[0] += xdir * (@gun.width + 2)
    @position[1] += ydir * (@gun.height + 2)
    @life = life
    # @update()
    # console.log 'new bullet at', @position, @gun.player.id

  getState: ->
    Object.assign super(),
      life: @life
      damage: @damage
      gun: @gun.getState()

  setState: (state) ->
    super state
    {@life, @damage} = state

  updateVelocity: -> # bullet velocity is constant

  update: ->
    super()
    @life--
