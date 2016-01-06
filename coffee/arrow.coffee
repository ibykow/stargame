if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

{atan2, min, sqrt} = Math
pi = Math.PI
isarr = Array.isArray

(module ? {}).exports = class Arrow extends View
  constructor: (@game, @params) ->
    return unless @game? and @params.a? and @params.b?
    {@a, @b, @color, @lineWidth} = @params
    return unless isarr(@a.view) and isarr(@b.view)
    conf = Config.client.arrow
    @color ?= conf.color
    @lineWidth ?= conf.lineWidth
    @enabled = true
    super @game, @params

  update: ->
    return unless @enabled
    @visible = true
    p = Util.toroidalDelta @a.view, @b.view, @game.toroidalLimit
    # p = @a.positionDelta @b
    p[2] = atan2 p[0], p[1]

    @theta = pi - p[2]
    @magnitude = sqrt(p[0] * p[0] + p[1] * p[1])

    if @magnitude < @game.canvas.halfHeight
      @viewAlpha = min @alpha, @magnitude / @game.canvas.halfHeight
    else
      @viewAlpha = @alpha

    super()

  draw: ->
    return unless @enabled
    top = (@magnitude * @game.canvas.halfHeight) / @game.width + 30
    side = top - 10
    bottom = min side, 25

    c = @game.c
    c.save()

    c.globalAlpha = @viewAlpha
    c.strokeStyle = @color
    c.lineWidth = @lineWidth

    c.translate @a.view[0], @a.view[1]
    c.rotate @theta

    c.beginPath()
    c.moveTo 0, bottom
    c.lineTo 3, side
    c.lineTo 8, side
    c.lineTo 0, top
    c.lineTo -8, side
    c.lineTo -3, side

    c.closePath()
    c.stroke()
    c.restore()
