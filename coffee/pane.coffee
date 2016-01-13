if require?
  Config = require './config'
  Util = require './util'
  ComponentView = require './componentview'

# Pane: A window-like pane which closes when the mouse leaves
(module ? {}).exports = class Pane extends ComponentView
  close: ->
    @game.stopUpdating @
    @visible = false
    @emit 'close'

  constructor: (@game, @params = {}) ->
    return unless @game?
    @params.alpha = @params.alpha ? 0.6
    @params.dimensions = @params.dimensions ? [360, 0]
    super @game, @params

  open: ->
    @game.startUpdating @
    @visible = true
    @emit 'open'

  resize: ->
    {width, height, halfHeight} = @game.canvas
    @view = [width - @dimensions[0], 0, 0]
    @dimensions[1] = height
    @halfHeight = halfHeight

  toggle: -> if @visible then @close() else @open()
