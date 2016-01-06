if require?
  Config = require './config'
  Facility = require './facility'

(module ? {}).exports = class GasStation extends Facility
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    @color = "#0F0"
    {@fuelPrice} = @params
    @fuelPrice ?= floor(Config.common.fuel.price.min + rnd() *
      (Config.common.fuel.price.max - Config.common.fuel.price.min) * 100) / 100
    super @game, @params

  getState: -> Object.assign super(), fuelPrice: @fuelPrice

  setState: (state) ->
    super state
    {@fuelPrice} = state

  insertView: ->
    @view = new FacilityView @game,
      offset: [@parent.halfWidth - @width, -2 - @parent.halfHeight]
