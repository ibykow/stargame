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
    @now 'hit', (model) => @damaged += model.damage
      # console.log '' + @ + ' took ' + model.damage + ' damage from ' + model

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

  update: ->
    @updateVelocity()
    super()
