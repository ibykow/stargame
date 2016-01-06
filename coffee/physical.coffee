if require?
  Config = require './config'
  Util = require './util'
  Model = require './model'

{trunc} = Math
isarr = Array.isArray

(module ? {}).exports = class Physical extends Model
  constructor: (@game, @params = {}) ->
    return unless @game?
    @isPhyiscal = true
    @magnitude = 0
    @collisions = {} # current collisions stored by type
    {@mass, @v0} = @params

    if @v0?.length
      @velocity = @v0.slice()
    else
      @v0 = [0, 0]
      @velocity = [0, 0]

    super @game, @params

  getState: ->
    Object.assign super(),
      isPhysical: @isRigid
      velocity: @velocity.slice()

  setState: (state) ->
    super state
    {@isPhyiscal, @velocity} = state

  update: ->
    super()
    @updateVelocity()

  updateVelocity: ->
    {friction} = @game.rates
    @velocity[0] = trunc(@velocity[0] * friction * 100) / 100
    @velocity[1] = trunc(@velocity[1] * friction * 100) / 100
    @magnitude = Util.magnitude @velocity
