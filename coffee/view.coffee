if require?
  Config = require './config'
  Util = require './util'
  Eventable = require './eventable'

# View: Something that can be seen on screen
(module ? {}).exports = class View extends Eventable
  constructor: (@game, @params) ->
    return unless @game?
    conf = Config.client.view
    {@alpha, @mouse, @offset} = @params
    @resize = @params.resize or @resize
    @alpha ?= 1
    @visible = false
    @offset ?= [0, 0]
    @game.on 'resize', @resize.bind(@), 0, true
    @view = [0, 0, 0]
    super @game, @params

    for name, callback of conf.mouse.events
      @immediate 'mouse-' + name, callback.bind(@), 0, true

  getBounds: -> [[0, 0], [1, 1]]

  getState: ->
    Object.assign super(),
      alpha: @alpha
      offset: @offset
      view: @view

  setState: (state) ->
    super state
    {@alpha, @offset, @view} = state

  resize: -> # called when the window is resized
  update: -> @game.visibleViews.push @ if @visible
  draw: ->
