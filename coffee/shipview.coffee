if require?
  Config = require './config'
  Util = require './util'
  ModeledView = require './modeledview'

(module ? {}).exports = class ShipView extends ModeledView
  @primaryUpdate: ->
    [x, y, r, vx, vy, halfw, halfh] =
      [ @model.position[0], @model.position[1], @model.position[2],
        @model.velocity[0], @model.velocity[1],
        @game.canvas.halfWidth, @game.canvas.halfHeight ]

    @view = [halfw + vx, halfh + vy, r]
    # @game.screenOffset = [x - vx - halfw, y - vy - halfh]
    @game.screenOffset = [x - halfw, y - halfh]

    # The current player's ship is always visible
    @visible = true
    @game.visibleViews.push @

  constructor: (ship, isPrimary) ->
    return unless ship
    super ship.game, model: ship
    (@update = ShipView.primaryUpdate.bind @)() if isPrimary

  drawFuel: (x, y) ->
    c = @game.c
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

  drawHalo: (color = '#0F0', alpha = 0.4, thickness = 4, margin = 3) ->
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
    c.save()
    c.fillStyle = @model.color
    c.translate @view...
    c.rotate @view[2]
    c.globalAlpha = @alpha
    c.beginPath()
    c.moveTo 10, 0
    c.lineTo -10, 5
    c.lineTo -10, -5
    c.closePath()
    c.fill()
    @drawMuzzleFlash() if @firing
    @drawHalo '#F00', (min 5, @damaged) / 5, 8 if @damaged
    c.restore()
