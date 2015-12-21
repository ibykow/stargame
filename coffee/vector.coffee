if require?
  Util = require './util'

(module ? {}).exports = class Vector
  constructor: (@game, @a, @b, @color, @alpha, @id) ->
    return unless @game and @a and @b
    @color ?= "#0f0"
    @update()
    @alpha ?= 1

  update: ->
    limit = [@game.width, @game.height]
    p = @position = Util.toroidalDelta(@a.view, @b.view, limit)

    @magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1])

    if @magnitude < @game.canvas.halfHeight
      @viewAlpha = Math.min @alpha, @magnitude / @game.canvas.halfHeight
    else
      @viewAlpha = @alpha

    @position[2] = Math.atan2(p[0], p[1])
    @view = [p[0], p[1], Math.PI - p[2]]

  draw: ->
    top = (@magnitude * @game.canvas.halfHeight) / @game.width + 30
    side = top - 10
    bottom = Math.min(side, 25)
    c = @game.c

    c.save()
    c.translate(@a.view[0], @a.view[1])
    c.rotate(@view[2])

    c.globalAlpha = @viewAlpha
    c.strokeStyle = @color
    c.lineWidth = 0.5

    c.beginPath()
    c.moveTo(0, bottom)
    c.lineTo(3, side)
    c.lineTo(8, side)
    c.lineTo(0, top)
    c.lineTo(-8, side)
    c.lineTo(-3, side)
    c.moveTo(0, bottom)

    c.stroke()
    c.closePath()
    c.restore()
