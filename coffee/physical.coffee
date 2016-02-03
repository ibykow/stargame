if require?
  Config = require './config'
  Util = require './util'
  Model = require './model'

{atan2, trunc} = Math
isarr = Array.isArray

(module ? {}).exports = class Physical extends Model
  constructor: (@game, @params = {}) ->
    return unless @game?
    {@holographic, @mass, @velocity} = @params
    @collisions = {} # current collisions stored by type
    @damaged = 0
    @holographic ?= false
    @magnitude = 0
    @physical = true
    @velocity ?= [0, 0]

    super @game, @params

  initHandlers: ->
    super()
    @now 'hit', (model) => @damaged += model.damage unless @holographic

  getState: ->
    Object.assign super(),
      damaged: @damaged
      velocity: @velocity.slice()

  setState: (state) ->
    super state
    {@damaged, @velocity} = state

  updateVelocity: ->
    # {friction} = @game.rates
    # @velocity[0] = trunc(@velocity[0] * friction * 100) / 100
    # @velocity[1] = trunc(@velocity[1] * friction * 100) / 100
    @magnitude = Util.magnitude @velocity
    @heading = (Util.TWO_PI * atan2 @velocity[1], @velocity[0]) % Util.TWO_PI
    if @magnitude then @swivel = @rotation - @heading
    else @swivel = 0

  updatePosition: ->
    [a, b] = @position
    x = trunc((@position[0] + @velocity[0] + @game.width) * 100) / 100
    y = trunc((@position[1] + @velocity[1] + @game.height) * 100) / 100
    x %= @game.width
    y %= @game.height

    @position[0] = x
    @position[1] = y
    @rotation = (@rotation + Util.TWO_PI) % Util.TWO_PI

    unless (a is @position[0]) and (b is @position[1])
      @updatePartition()
      @emit 'move', [a, b]

  update: ->
    @updateVelocity()
    @updatePosition()
    super()
