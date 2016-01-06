if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

# ModeledView: View of an underlying model
(module ? {}).exports = class ModeledView extends View
  constructor: (@game, @params) ->
    return unless @game? and @params?.model
    {@model} = @params
    super @game, @params

  getBounds: ->
    {width, height, halfWidth, halfHeight} = @model
    [[@view[0] - halfWidth, @view[1] - halfHeight], [width, height]]

  isOnScreen: ->
    w = @model.halfWidth
    h = @model.halfHeight
    cw = @game.canvas.width
    ch = @game.canvas.height
    @game.c? and (@view[0] >= -w) and (@view[1] >= -h) and
      (@view[0] <= cw + w) and (@view[1] <= ch + h)

  update: ->
    {screenOffset, toroidalLimit} = @game

    # Generate a view based on the model
    @view = Util.toroidalDelta @model.position, screenOffset, toroidalLimit

    # Set the offsets
    @view[0] += @offset[0]
    @view[1] += @offset[1]
    @view[2] = @model.position[2]

    # Check and update visibility
    @visible = @isOnScreen()
    super()

  # Simple. Draw a box based on the model
  draw: ->
    {color, width, height, halfWidth, halfHeight} = @model
    c = @game.c
    c.globalAlpha = @alpha
    c.fillStyle = color
    c.fillRect  @view[0] - halfWidth, @view[1] - halfHeight, width, height
    c.globalAlpha = 1
