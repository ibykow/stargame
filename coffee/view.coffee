if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'

# View: Something that can be seen on screen
(module ? {}).exports = class View extends Emitter
  constructor: (@game, @params) ->
    return unless @game?
    conf = Config.client.view
    {@alpha, @mouse, @offset} = @params
    @resize = @params.resize or @resize
    @alpha ?= 1
    @visible = false
    @offset ?= [0, 0]
    @game.on 'resize', @resize.bind @
    @view = [0, 0, 0]
    super @game, @params

    for name, callback of conf.mouse.events
      @now 'mouse-' + name, callback.bind(@), 0, true

  arrowTo: (view, color, alpha = 1, lineWidth = 1) ->
    new Arrow @game,
      a: @
      b: view
      color: color ? view.model.color
      alpha: alpha
      lineWidth: lineWidth

  delete: ->
    # Collect and remove any arrows pointing to the ship
    if @game.lib['Arrow']?
      for id, arrow of @game.lib['Arrow']
        arrow.delete() if (arrow.a.id is @id) or (arrow.b.id is @id)

    super()

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
