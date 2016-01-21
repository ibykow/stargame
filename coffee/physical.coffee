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
          callback: (bullet) ->
            bullet.life = 0
            @damaged += bullet.damage

    (@[type] name, info for name, info of event) for type, event of events

  getState: ->
    Object.assign super(),
      damaged: @damaged
      velocity: @velocity.slice()

  setState: (state) ->
    super state
    {@damaged, @velocity} = state

  update: ->
    super()
    @updateVelocity()

  updateVelocity: ->
    {friction} = @game.rates
    @velocity[0] = trunc(@velocity[0] * friction * 100) / 100
    @velocity[1] = trunc(@velocity[1] * friction * 100) / 100
    @magnitude = Util.magnitude @velocity
