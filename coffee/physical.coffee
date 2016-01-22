if require?
  Config = require './config'
  Util = require './util'
  Model = require './model'

{trunc} = Math
isarr = Array.isArray

(module ? {}).exports = class Physical extends Model
  constructor: (@game, @params = {}) ->
    return unless @game?
    @physical = true
    @damaged = 0
    @magnitude = 0
    @collisions = {} # current collisions stored by type
    {@mass, @velocity} = @params

    @velocity ?= [0, 0]

    super @game, @params

  initEventHandlers: ->
    super()

    events =
      now:
        hit:
          bind: [@]
          timer: 0
          repeats: true
          callback: (model) ->
            model.life = 0 if model.type is 'Projectile'
            console.log @type, @id, 'hit by', model.type, model.id, model.damage
            @damaged += model.damage

    (@[type] name, info for name, info of event) for type, event of events

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
    # z = trunc (((@rotation + Util.TWO_PI) % Util.TWO_PI) * 100) / 100
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
