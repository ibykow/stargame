if require?
  Config = require './config'
  Util = require './util'
  Pane = require './pane'

(module ? {}).exports = class Minimap extends Pane
  constructor: (@game, @params = {}) ->
    {@size, @zoom} = @params
    @size ?= 100
    @zoom = 4 unless (@zoom >= 1) and (@zoom <= 8)
    @params.visible = true
    super @game, @params
    @resize()

  getState: -> Object.assign super(),
    size: @size
    zoom: @zoom

  setState: (state) ->
    super state
    {@size, @zoom} = state

  draw: ->
    c = @game.c
    c.globalAlpha = 1
    c.fillStyle = '#000'
    c.strokeStyle = '#0F0'
    c.lineWidth = 2

    c.beginPath()
    c.arc @offset[0], @offset[1], @size, 0, Util.TWO_PI
    c.closePath()

    c.fill()
    c.stroke()
    c.globalAlpha = 1

  resize: ->
    @offset = [@game.canvas.width - @size - 15, @game.canvas.height - @size - 5]
    cm = @game.contextMenu
    @offset[0] -= cm.dimensions[0] - 10 if cm.visible
