if require?
  Util = require './util'
  Config = require './config'
  Sprite = require './sprite'
  Button = require './button'

{abs, floor, sqrt, round, trunc} = Math
isarr = Array.isArray
rnd = Math.random

pesoChar = Config.common.chars.peso

(module ? {}).exports = class GasStation extends Sprite
  constructor: (@parent, @fuelPrice, @buttonState, @stationIndex = -1) ->
    return unless @parent
    super @parent.game, @parent.position.slice(), 9, 9
    @position[0] += @parent.halfWidth - 4
    @position[1] -= @parent.halfHeight + 2
    @fuelPrice ?= Config.common.fuel.price.min + rnd() *
      (Config.common.fuel.price.max - Config.common.fuel.price.min)

    # used for finding gas stations in the game gasStations list
    if ~@stationIndex
      @game.gasStations[@stationIndex] = @
    else
      @stationIndex = (@game.gasStations.push @) - 1

    @parent.adopt @

    if @buttonState
      @appendButton @buttonState
    else
      params = Config.common.button
      params.width = 160
      params.height = 32
      params.default.enabled = false

      @buttonState =
        text: 'Fill up for ' + pesoChar + @fuelPrice.toFixed(2) + '/L'
        params: params

  @fromState: (parent, state) ->
    # console.log 'creating gas station from', state, parent.constructor.name
    new GasStation parent, state.fuelPrice, state.button, state.stationIndex

  appendButton: (state) ->
    # Create the button. This only happens on the client side.
    @click = (b) =>
      return unless b.enabled
      b.enabled = false
      @game.player.gasStationIndex = @stationIndex
      @game.player.inputs.push 'refuel'

    button = new Button @, 'fillUpButton', @click, state.text, state.params

    # enable mouse events
    @mouse.enter = -> button.enabled = true
    button.mouse.leave = -> button.enabled = false

  getState: ->
    Object.assign super(),
      fuelPrice: @fuelPrice
      button: @buttonState
      stationIndex: @stationIndex

  setState: (state) ->
    super state
    {@fuelPrice, @buttonState, @stationIndex} = state

  # updatePosition - enable if stars move around
  # updatePosition: ->
  #   @position = [ @parent.position[0],
  #                 @parent.position[1] - 9,
  #                 @parent.position[2]]

  draw: -> # we don't get called unless the parent is visible
    @game.c.fillStyle = "#0f0"
    @game.c.font = "14px Courier New"
    @game.c.fillText 'G', @view[0] - 5, @view[1]
