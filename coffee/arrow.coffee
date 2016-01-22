if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

{atan2, min, PI, sqrt} = Math
isarr = Array.isArray

(module ? {}).exports = class Arrow extends View
  constructor: (@game, @params) ->
    return unless @game? and @params.a? and @params.b?
    {@a, @b, @color, @lineWidth} = @params
    return unless @a.isView and @b.isView
    conf = Config.client.arrow
    @color ?= conf.color
    @lineWidth ?= conf.lineWidth
    super @game, @params

  delete: ->
    @deleted = true
    super arguments[0]

  draw: ->
    @transform()

    c = @game.c
    c.globalAlpha = @alpha

    c.strokeStyle = @color
    c.lineWidth = @lineWidth

    c.beginPath()
    c.moveTo 0, @bottom
    c.lineTo 3, @side
    c.lineTo 8, @side
    c.lineTo 0, @top
    c.lineTo -8, @side
    c.lineTo -3, @side
    c.closePath()
    c.stroke()

    @restore()

  update: ->
    @offset = @a.offset.slice()
    delta = @a.offsetDelta @b
    @rotation = PI - atan2 delta...
    @magnitude = sqrt delta.reduce (a, b) -> a + b * b
    @alpha = min 1, @magnitude / @game.canvas.halfHeight
    @top = (@magnitude * @game.canvas.halfHeight) / @game.width + 30
    @side = @top - 10
    @bottom = min @side, 25
    super()
