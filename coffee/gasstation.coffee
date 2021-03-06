if require?
  Config = require './config'
  Facility = require './facility'

{floor} = Math
rnd = Math.random

(module ? {}).exports = class GasStation extends Facility
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    {@fuelPrice} = @params
    @fuelPrice ?= floor(Config.common.fuel.price.min + rnd() *
      (Config.common.fuel.price.max - Config.common.fuel.price.min) * 100) / 100

    @params.color = '#0F0'
    @params.emblemCharacter = 'G'

    super @game, @params

  getState: -> Object.assign super(), fuelPrice: @fuelPrice

  setState: (state) ->
    super state
    {@fuelPrice} = state
