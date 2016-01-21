if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

{sqrt} = Math

(module ? {}).exports = class Explosion extends View
  constructor: (@game, params = alwaysUpdate: true) ->
    return unless @game?

    {@position, @radius} = params
    @frames = 60
    @life = @frames
    params.alwaysUpdate = true
    @position ?= [0, 0]
    @radius ?=
      current: 50
      final: 200
      initial: 50

    @radius.current ?= @radius.initial
    @radius.delta = @radius.final - @radius.initial
    super @game, params

  draw: ->
    c = @game.c
    c.globalAlpha = @rate
    c.fillStyle = '#fff'
    # c.fillStyle = 'rgb(' + @shade + ',' + @shade + ',255)'
    c.beginPath()
    c.arc @view[0], @view[1], @radius.current, 0, Util.TWO_PI
    c.closePath()
    c.fill()
    c.globalAlpha = 1

  getState: -> Object.assign super(),
    position: @position
    radius: @radius

  isOnScreen: ->
    (@view[0] > -@radius.current) and (@view[1] > -@radius.current) and
    (@view[0] + @radius.current < @game.canvas.width) and
    (@view[1] + @radius.current < @game.canvas.height)

  setState: (state) ->
    super state
    @position = state.position
    @radius = state.radius

  update: ->
    return @delete() unless @life-- > 0
    {screenOffset, toroidalLimit} = @game

    @rate = @life / @frames
    @rate *= @rate
    @radius.current = @radius.delta * (1 - @rate)
    @shade = @rate * 0xFF

    @view = Util.toroidalDelta @position, screenOffset, toroidalLimit
    @visible = @isOnScreen()
    super()
