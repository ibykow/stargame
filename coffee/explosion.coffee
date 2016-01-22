if require?
  Config = require './config'
  Util = require './util'
  Model = require './model'
  Physical = require './physical'
  ExplosionView = require './explosionview'

{abs, ceil, floor, max} = Math

(module ? {}).exports = class Explosion extends Physical
  constructor: (@game, params = {}) ->
    return unless @game?

    {name} = params
    name ?= 'default'
    unless Config.common.explosions[name]?
      console.log 'Explosion type', name, 'not found'
      name = 'default'

    conf = Config.common.explosions[name]

    @colors = params.colors or conf.colors
    @damageRate = params.damageRate or conf.damageRate
    @strength = params.strength or conf.strength
    @life = @strength
    params.alwaysUpdate = true
    super @game, params

  getState: -> Object.assign super(),
    colors: @colors
    damageRate: @damageRate
    life: @life
    strength: @strength

  insertView: -> @view = new ExplosionView @game, model: @

  setState: (state) ->
    super state
    {@colors, @damageRate, @life, @strength} = state

  update: ->
    unless @life > 0
      return @delete 'because it fizzled out'
    super()
    @rate = @life / @strength
    @rate *= @rate

    @life--

    @radius = @strength * (1 - @rate)

    return unless @damage = floor @strength * @damageRate * @rate
    # Collision detection
    models = @around ceil @radius / @game.partitionSize
    proximity = max @magnitude - 1, 1
    for model in models when not (model.id is @id)
      model.emit 'hit', @ if proximity > abs @radius - @distanceTo model
