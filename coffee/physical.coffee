if require?
  Config = require './config'
  Util = require './util'
  Model = require './model'

{trunc} = Math
isarr = Array.isArray

(module ? {}).exports = class Physical extends Model
  constructor: (@game, @params = {}) ->
    return unless @game?
    {@mass, @velocity} = @params
    @collisions = {} # current collisions stored by type
    @damaged = 0
    @magnitude = 0
    @physical = true
    @velocity ?= [0, 0]

    super @game, @params

  initHandlers: ->
    super()
    @now 'hit', (model) =>
      model.life = 0 if model.type is 'Projectile'
      console.log '' + @ + ' was hit by ' + model + ' at ' + model.damage
      @damaged += model.damage

  getState: ->
    Object.assign super(),
      damaged: @damaged
      velocity: @velocity.slice()

  setState: (state) ->
    super state
    {@damaged, @velocity} = state

  updateVelocity: ->
    {friction} = @game.rates
    @velocity[0] = trunc(@velocity[0] * friction * 100) / 100
    @velocity[1] = trunc(@velocity[1] * friction * 100) / 100
    @magnitude = Util.magnitude @velocity

  updatePosition: ->
    x = trunc((@position[0] + @velocity[0] + @game.width) * 100) / 100
    y = trunc((@position[1] + @velocity[1] + @game.height) * 100) / 100
    x %= @game.width
    y %= @game.height

    @position[0] = x
    @position[1] = y

  update: ->
    super()
    [x, y] = @position
    @updateVelocity()
    @updatePosition()
    @emit 'move' unless (x is @position[0]) and (y is @position[1])
