if require?
  Config = require './config'
  Util = require './util'
  View = require './view'

# ComponentView: A view grouped with another
(module ? {}).exports = class ComponentView extends View
  constructor: (@game, @params) ->
    return unless @game?

    {@dimensions, @colors, @offset} = @params
    @dimensions ?= [100, 50]
    @halfDimensions = [@dimensions[0] / 2, @dimensions[1] / 2]
    @colors ?=
      text: '#FFF'
      background:
        current: '#444'
        hover: '#666'
        leave: '#444'

    super @game, @params
    @offset.length = 2

    {hover, leave} = @colors.background

    @now 'mouse-enter', => @colors.background.current = hover
    @now 'mouse-leave', => @colors.background.current = leave
    @now 'mouse-press', => @colors.background.current = leave
    @now 'mouse-release', => @colors.background.current = hover

  getBounds: -> [[@view[0], @view[1]], @dimensions]

  getState: ->
    Object.assign super(),
      alpha: @alpha
      colors: @colors
      offset: @offset
      view: @view

  setState: (state) ->
    super state
    {@alpha, @colors, @offset, @view} = state

  draw: ->
    c = @game.c
    c.globalAlpha = @alpha
    c.fillStyle = @colors.background.current
    c.fillRect @view[0], @view[1], @dimensions...
    c.globalAlpha = 1
