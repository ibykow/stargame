if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

# ComponentView: A view grouped with another
(module ? {}).exports = class ComponentView extends View
  constructor: (@game, @params) ->
    return unless @game?

    {@colors, @dimensions} = @params
    @dimensions ?= [100, 50]
    @halfDimensions = [@dimensions[0] / 2, @dimensions[1] / 2]
    @colors ?=
      text: '#FFF'
      background:
        current: '#444'
        hover: '#666'
        leave: '#444'

    super @game, @params

    {hover, leave} = @colors.background

    @now 'mouse-enter', => @colors.background.current = hover
    @now 'mouse-leave', => @colors.background.current = leave
    @now 'mouse-press', => @colors.background.current = leave
    @now 'mouse-release', => @colors.background.current = hover

  getBounds: -> [@offset, @dimensions]

  getState: ->
    Object.assign super(),
      colors: @colors
      dimensions: @dimensions

  setState: (state) ->
    super state
    {@colors, @dimensions} = state

  draw: ->
    super()
    c = @game.c
    c.fillStyle = @colors.background.current
    c.fillRect 0, 0, @dimensions...
    @restore()
