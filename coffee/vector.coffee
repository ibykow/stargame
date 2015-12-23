if require?
  Util = require './util'

(module ? {}).exports = class Vector
  constructor: (@game, @a, @b, @color = "#0f0", @alpha = 1,
  @lineWidth = 0.5, @id) ->
    return unless @game and @a and @b
    # @update()

  update: ->
    limit = [@game.width, @game.height]
    p = @position = Util.toroidalDelta(@a.view, @b.view, limit)

    @magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1])
    @position[2] = Math.atan2(p[0], p[1])
    @view = [p[0], p[1], Math.PI - p[2]]

    if @magnitude < @game.canvas.halfHeight
      @view[3] = Math.min @alpha, @magnitude / @game.canvas.halfHeight
    else
      @view[3] = @alpha

  draw: ->
    top = (@magnitude * @game.canvas.halfHeight) / @game.width + 30
    side = top - 10
    bottom = Math.min(side, 25)
    c = @game.c

    c.save()
    c.translate(@a.view[0], @a.view[1])
    c.rotate(@view[2])

    c.globalAlpha = @view[3]
    c.strokeStyle = @color
    c.lineWidth = @lineWidth

    c.beginPath()
    c.moveTo(0, bottom)
    c.lineTo(3, side)
    c.lineTo(8, side)
    c.lineTo(0, top)
    c.lineTo(-8, side)
    c.lineTo(-3, side)

    c.closePath()
    c.stroke()
    c.restore()
