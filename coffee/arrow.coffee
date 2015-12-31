if require?
  Util = require './util'

(module ? {}).exports = class Arrow
  constructor: (@game, @a, @b, @color = "#0f0", @alpha = 1,
  @lineWidth = 0.5, @id) ->
    return unless @game and @a and @b
    @magnitude = 0
    @prevMagnitude = 0

  update: ->
    #Util.toroidalDelta @a.view, @b.view, @game.toroidalLimit
    p = a.positionDelta b
    p[2] = Math.atan2(p[0], p[1])

    @theta = Math.PI - p[2]
    @magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1])

    if @magnitude < @game.canvas.halfHeight
      @viewAlpha = Math.min @alpha, @magnitude / @game.canvas.halfHeight
    else
      @viewAlpha = @alpha

  draw: ->
    top = (@magnitude * @game.canvas.halfHeight) / @game.width + 30
    side = top - 10
    bottom = Math.min(side, 25)
    c = @game.c

    c.save()
    c.translate(@a.view[0], @a.view[1])
    c.rotate @theta

    c.globalAlpha = @viewAlpha
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
