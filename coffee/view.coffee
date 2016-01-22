if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'

# View: Something that can be seen on screen
(module ? {}).exports = class View extends Emitter
  constructor: (@game, @params = {}) ->
    return unless @game?

    {@alpha, @offset, @rotation, @visible} = @params
    @alpha ?= 1
    @offset ?= [0, 0]
    @rotation ?= 0

    @resize = @params.resize or @resize
    @game.on 'resize', @resize.bind @

    @visible ?= true
    @isView = true

    super @game, @params

  delete: ->
    # Collect and remove any arrows pointing to the ship
    if @game.lib['Arrow']?
      for id, arrow of @game.lib['Arrow'] when not arrow.deleted
        if (@equals arrow.a) or @equals arrow.b
          arrow.delete 'because ' + @ + ' was deleted'

    super arguments[0]

  draw: ->
    @game.c.globalAlpha = @alpha
    @transform()

  transform: ->
    @game.c.translate @offset...
    @game.c.rotate @rotation

    @game.deltas.offset = (n + @offset[i] for n, i in @game.deltas.offset)
    @game.deltas.rotation += @rotation

  restore: ->
    @game.deltas.offset = (n - @offset[i] for n, i in @game.deltas.offset)
    @game.deltas.rotation -= @rotation

    @game.c.rotate @rotation * -1
    @game.c.translate @offset.map((n) -> -n)...

  getBounds: -> [[0, 0], [1, 1]]

  getState: ->
    Object.assign super(),
      alpha: @alpha
      offset: @offset
      rotation: @rotation
      visible: @visible

  initEventHandlers: -> @on e, cb.bind @ for e, cb of Config.client.view.events

  offsetDelta: (target) ->
    Util.toroidalDelta @offset, target.offset, @game.toroidalLimit

  restoreRotation: ->
    @game.c.rotate @game.deltas.rotation * -1
    @game.deltas.rotation = 0

  restoreOffset: ->
    @game.c.translate @game.deltas.offset.map((n) -> -n)...

  setState: (state) ->
    super state
    {@alpha, @offset, @rotation, @visible} = state

  resize: -> # called when the window is resized
  update: -> @game.visibleViews.push @ if @visible
