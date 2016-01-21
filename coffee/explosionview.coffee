if require?
  Config = require './config'
  Util = require './util'
  ModeledView = require './modeledview'

(module ? {}).exports = class ExplosionView extends ModeledView
  draw: ->
    c = @game.c
    c.globalAlpha = @model.rate
    c.strokeStyle = '#ff0'
    c.fillStyle = '#fff'
    c.lineWidth = 5
    c.beginPath()
    c.arc @view[0], @view[1], @model.radius, 0, Util.TWO_PI
    c.closePath()
    c.stroke()
    c.fill()
    c.globalAlpha = 1

  isOnScreen: ->
    radius = @model.radius
    (@view[0] > -radius) and (@view[1] > radius) and
    (@view[0] + radius < @game.canvas.width) and
    (@view[1] + radius < @game.canvas.height)

  update: ->
    super()
    @shade = @model.rate * 0xFF
