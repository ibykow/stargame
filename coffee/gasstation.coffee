if require?
  Util = require './util'
  Config = require './config'
  Sprite = require './sprite'

[abs, floor, isarr, sqrt, rnd, round, trunc] = [Math.abs, Math.floor,
  Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc]

(module ? {}).exports = class GasStation extends Sprite
  constructor: (@parent, @fuelPrice) ->
    return unless @parent
    super @parent.game, @parent.position, 20, 20
    @fuelPrice ?= Config.common.fuel.price.min + rnd() *
      (Config.common.fuel.price.max - Config.common.fuel.price.min)

    @parent.adopt @
    @position = @parent.position

  getState: ->
    state = super()
    state.fuelPrice = @fuelPrice

  setState: (state) ->
    super state
    @fuelPrice = state.fuelPrice ? @fuelPrice

  draw: -> # we don't get called unless the parent is visible
    @game.c.fillStyle = "#0f0"
    @game.c.font = "14px Courier New"
    @game.c.fillText 'G', @view[0] + @parent.halfWidth, @view[1]
