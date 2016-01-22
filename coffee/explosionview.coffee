if require?
  Config = require './config'
  Util = require './util'
  ModeledView = require './modeledview'

(module ? {}).exports = class ExplosionView extends ModeledView
  draw: ->
    @transform()

    {colors, radius, rate} = @model
    c = @game.c
    c.globalAlpha = rate
    c.strokeStyle = colors.stroke
    c.fillStyle = colors.fill
    c.lineWidth = 5 * rate
    c.beginPath()
    c.arc 0, 0, radius, 0, Util.TWO_PI
    c.closePath()
    c.fill()
    c.stroke()
    @restore()

  isOnScreen: -> true

  update: ->
    super()
    @shade = @model.rate * 0xFF
