if require?
  Config = require './config'
  Util = require './util'
  ModeledView = require './modeledview'

(module ? {}).exports = class ShipView extends ModeledView

  drawFuel: (x, y) ->
    constructor: (@game, @params) ->
      @params.alwaysUpdate = true
      super @game, @params

    c = @game.c
    c.globalAlpha = 1
    if @model.fuel
      c.font = "10px Helvetica"
      remain = @model.fuel / @model.fuelCapacity
      rate = floor remain * 0xD0
      c.fillStyle = "rgba(" + (0xFF - rate) + "," + rate + "," + 0 + ",1)"
      c.fillRect x, y, floor(remain * 60), 16
      c.fillStyle = "#fff"
      c.fillText 'FUEL', x + 17, y + 12
    else
      c.font = "Bold 10px Helvetica"
      c.fillStyle = "#f00"
      c.fillText 'EMPTY', x + 12, y + 12

    c.strokeStyle = "#fff"
    c.lineWidth = 2
    c.strokeRect x, y, 60, 16

  drawHalo: (color = '#0F0', alpha = 0.4, thickness = 8, margin = 3) ->
    c = @game.c
    c.lineWidth = thickness
    c.strokeStyle = color
    c.globalAlpha = alpha
    padding = margin * thickness
    c.beginPath()
    c.moveTo 10 + padding, 0
    c.lineTo -padding, 5 + padding
    c.lineTo -padding, -5 - padding
    c.closePath()
    c.stroke()

  drawHealth: (x, y) ->
    c = @game.c
    c.globalAlpha = 1
    if @model.health > 0
      remain = @model.health / @model.maxHealth
      rate = floor remain * 0xD0
      c.fillStyle = "rgba(" + (0xFF - rate) + "," + rate + "," + 0 + ",1)"
      c.fillRect x, y, floor(remain * 60), 16
      c.fillStyle = "#fff"
      c.font = "10px Helvetica"
      c.fillText 'HEALTH', x + 10, y + 12
    else
      c.font = "Bold 10px Helvetica"
      c.fillStyle = "#f00"
      c.fillText 'DEAD', x + 16, y + 12

    c.strokeStyle = "#fff"
    c.lineWidth = 2
    c.strokeRect x, y, 60, 16

  drawHUD: (x = 260, y = 2) ->
    @drawHealth x, y
    @drawFuel x, y + 20

  drawMuzzleFlash: ->
    c = @game.c
    c.fillStyle = '#FF0'
    c.globalAlpha = 1
    c.beginPath()
    c.moveTo 12, 0
    c.lineTo 18, 10
    c.lineTo 16, 3
    c.lineTo 23, 6
    c.lineTo 18, 2
    c.lineTo 28, 0
    c.lineTo 18, -2
    c.lineTo 23, -6
    c.lineTo 16, -3
    c.lineTo 18, -10
    c.closePath()
    c.fill()
    c.fillRect 32, -1, 2, 2

  draw: ->
    c = @game.c
    c.globalAlpha = @alpha
    @transform()
    c.fillStyle = @model.color

    c.beginPath()
    c.moveTo 10, 0
    c.lineTo -10, 5
    c.lineTo -10, -5
    c.closePath()
    c.fill()

    @drawMuzzleFlash() if @model.firing
    @drawHalo '#F00', (min 5, @model.damaged) / 5 if @model.damaged

    @restore()
