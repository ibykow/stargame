if require?
  Util = require './util'
  Config = require './config'
  Pane = require './Pane'

(module ? {}).exports = class ChildPane extends Pane
  constructor: (@parent, @name, @offset, @width, @height, @color) ->
    return unless @parent

    { @width, @height, @colors } = @params

    super @parent.game, @parent.view, @width, @height, @color

    @parent.adopt @, @name
    @visible = true
    @offset ?= [0, 0]

  updateView: ->
    @view[0] = @parent.view[0] + @offset[0]
    @view[1] = @parent.view[1] + @offset[1]
