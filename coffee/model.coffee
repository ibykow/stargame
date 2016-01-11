if require?
  Config = require './config'
  Util = require './util'
  Eventable = require './eventable'

conf = Config.common.model
{abs, trunc} = Math
isarr = Array.isArray

# Model: Something that exists in the game world
(module ? {}).exports = class Model extends Eventable
  constructor: (@game, @params) ->
    return unless @game?
    @deleted = false
    {@color, @position, @width, @height} = @params
    @color ?= Util.randomColorString()
    @offset ?= [0, 0]

    unless @position?.length
      if @parent then @position = @parent.position
      else @position = @game.randomPosition()

    @width ?= conf.width
    @height ?= conf.height

    @halfWidth = @width / 2
    @halfHeight = @height / 2
    super @game, @params

  distanceTo: (model) -> Util.magnitude @positionDelta model

  positionDelta: (model) ->
    return [0, 0] unless model?.position.length
    Util.toroidalDelta @position, model.position, @game.toroidalLimit

  intersects: (model) ->
    return false if @ is model
    delta = @positionDelta model
    (abs(delta[0]) <= @halfWidth + model.halfWidth) and
    (abs(delta[1]) <= @halfHeight + model.halfHeight)

  getBounds: ->
    x = @position[0] - @halfWidth
    y = @position[1] - @halfHeight
    [[x, y], [@width, @height]]

  getState: ->
    Object.assign super(),
      deleted: @deleted
      color: @color
      position: @position.slice()
      width: @width
      height: @height

  setState: (state) ->
    super state
    {@deleted, @color, @position, @width, @height} = state

  updatePosition: ->
    x = trunc((@position[0] + @velocity[0] + @game.width) * 100) / 100
    y = trunc((@position[1] + @velocity[1] + @game.height) * 100) / 100
    z = trunc (((@position[2] + Util.TWO_PI) % Util.TWO_PI) * 100) / 100
    x %= @game.width
    y %= @game.height

    @position[0] = x
    @position[1] = y

  update: ->
    @updatePosition()
    child.update() for type, child of @children

  insertView: -> @view = new ModeledView @game, model: @
