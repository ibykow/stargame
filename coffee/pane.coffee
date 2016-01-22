if require?
  Config = require './config'
  Util = require './util'
  ComponentView = require './componentview'

# Pane: A window-like pane which closes when the mouse leaves
(module ? {}).exports = class Pane extends ComponentView
  close: ->
    @visible = false
    @emit 'close'

  constructor: (@game, @params = {}) ->
    return unless @game?
    @params.alpha = @params.alpha ? 0.6
    @params.dimensions = @params.dimensions ? [360, 0]
    super @game, @params

  open: ->
    @visible = true
    @emit 'open'

  resize: ->
    {height, width, halfHeight, halfWidth} = @game.canvas
    @offset = [width - @dimensions[0], 0, 0]
    # @dimensions[0] = width
    # @halfWidth = halfWidth
    @dimensions[1] = height
    @halfHeight = halfHeight

  toggle: -> if @visible then @close() else @open()
