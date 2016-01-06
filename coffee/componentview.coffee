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

    handler = @immediate 'mouse-enter', =>
      @colors.background.current = @colors.background.hover

    handler.repeats = true

    handler = @immediate 'mouse-leave', =>
      @colors.background.current = @colors.background.leave

    handler.repeats = true

    handler = @immediate 'mouse-press', =>
      @colors.background.current = @colors.background.leave

    handler.repeats = true

    handler = @immediate 'mouse-release', =>
      @colors.background.current = @colors.background.hover

    handler.repeats = true

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
