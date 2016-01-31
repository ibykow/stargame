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
    [[@offset[0] - halfWidth, @offset[1] - halfHeight], [width, height]]

  initHandlers: ->
    super()
    # Pass mouse events on to the model
    for type in Config.client.mouse.event.types
      @now 'mouse-' + type, (data, handler) => @model.emit handler.name, data

  isOnScreen: ->
    (@offset[0] + @model.halfWidth > 0) and
    (@offset[1] + @model.halfHeight > 0) and
    (@offset[0] - @model.halfWidth < @game.canvas.width) and
    (@offset[1] - @model.halfHeight < @game.canvas.height)

  update: ->
    {screenOffset, toroidalLimit} = @game

    # Generate a view based on the model
    @offset = Util.toroidalDelta @model.position, screenOffset, toroidalLimit
    @rotation = @model.rotation

    # Check and update visibility
    @visible = @isOnScreen()
    super()

  # Simple. Draw a box based on the model
  draw: ->
    super()
    {color, width, height, halfWidth, halfHeight} = @model
    c = @game.c
    c.fillStyle = color
    c.fillRect -halfWidth, -halfHeight, width, height
    @restore()
