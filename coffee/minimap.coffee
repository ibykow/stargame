if require?
  Config = require './config'
  Util = require './util'
  Pane = require './pane'

{ceil, sqrt} = Math

(module ? {}).exports = class Minimap extends Pane
  constructor: (@game, @params = {}) ->
    {@size, @zoom} = @params
    @count = 0
    @size ?= 100
    @zoom = 100
    @params.visible = false
    @lib = {}
    super @game, @params

  getState: -> Object.assign super(),
    size: @size
    zoom: @zoom

  setState: (state) ->
    super state
    {@size, @zoom} = state

  draw: ->
    @transform()
    c = @game.c
    c.fillStyle = '#000'
    c.strokeStyle = '#888'
    c.lineWidth = 4

    c.globalAlpha = 0.8
    c.beginPath()
    c.arc 0, 0, @size, 0, Util.TWO_PI
    c.closePath()
    c.fill()

    c.beginPath()
    c.arc 0, 0, @size + 2, 0, Util.TWO_PI
    c.closePath()

    c.stroke()

    c.globalAlpha = 1

    for type, model of @lib
      for id, info of model
        c.fillStyle = info.color
        c.fillRect info.offset[0], info.offset[1], info.size, info.size

    ship = @game.player.ship
    c.fillStyle = ship.color

    c.rotate ship.rotation

    c.beginPath()
    c.moveTo 5, 0
    c.lineTo -5, 3
    c.lineTo -5, -3
    c.closePath()
    c.fill()

    if length = min 14, ceil ship.magnitude / 5
      c.fillStyle = '#FFF'
      c.beginPath()
      c.moveTo -7.5, 2.5
      c.lineTo -8 - length, 0
      c.lineTo -7.5, -2.5
      c.closePath()
      c.fill()

    if ship.accelerating and (ship.gear > 0)
      c.fillStyle = '#00F'
      c.beginPath()
      c.moveTo -6, 2.5
      c.lineTo -12, 0
      c.lineTo -6, -2.5
      c.closePath()
      c.fill()

    c.rotate ship.rotation * -1

    @restore()

  resize: ->
    x = @game.canvas.width - @size - 20
    y = @game.canvas.height - @size - 10
    @offset = [x, y]
    @updateRange()

  track: (model, color) ->
    return unless model?.type
    return if model.deleted

    model.now 'delete', (data, handler) => @untrack handler.target

    @lib[model.type] ?= {}
    @lib[model.type][model.id] =
      color: color or model.color or '#0F0'
      model: model
      size: 3

    @count++
    @visible = true

  untrack: (model) ->
    return unless model and info = @lib[model.type]?[model.id]
    delete @lib[model.type][model.id]
    @count--
    @visible = false unless @count

  update: ->
    return unless ship = @game.player.ship
    super()
    for name, types of @lib
      for id, info of types
        info.delta = info.model.positionDelta ship
        [x, y] = info.delta
        m = sqrt x*x + y*y

        if m > @range then ratio = @size / m else ratio = @ratio
        x *= ratio
        y *= ratio

        info.position = [x, y]
        info.offset = [x - 1,y - 1]

  updateRange: ->
    @range = @game.size * 10 / @zoom
    @ratio = @size / @range
    @parts = @range / @game.partitionSize

  zoomIn: ->
    return unless @zoom < 500
    @zoom++
    @page 'Zooming in to ' + @zoom / 10
    @updateRange()

  zoomOut: ->
    return unless @zoom > 10
    @zoom--
    @page 'Zooming out to ' + @zoom / 10
    @updateRange()
