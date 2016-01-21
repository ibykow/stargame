if require?
  Config = require './config'
  Util = require './util'
  Physical = require './physical'
  ExplosionView = require './explosionview'

(module ? {}).exports = class Explosion extends Physical
  constructor: (@game, params = alwaysUpdate: true) ->
    return unless @game?

    {@life, @strength} = params
    unless @strength?
      @strength = 100
      @life = @strength

    params.alwaysUpdate = true
    super @game, params

  getState: -> Object.assign super(),
    position: @position
    radius: @radius

  insertView: -> @view = new ExplosionView @game, model: @

  setState: (state) ->
    super state
    @position = state.position
    @radius = state.radius

  update: ->
    return @delete() unless @life > 0

    @rate = @life / @strength
    @rate *= @rate

    @life--

    @radius = @strength * (1 - @rate)
