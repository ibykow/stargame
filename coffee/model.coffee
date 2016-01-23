if require?
  Config = require './config'
  Util = require './util'
  Emitter = require './emitter'

conf = Config.common.model
{abs, floor, trunc} = Math
isarr = Array.isArray

# Model: Something that exists in the game world
(module ? {}).exports = class Model extends Emitter
  constructor: (@game, @params = {}) ->
    return unless @game?
    {@color, @partition, @position, @rotation, @width, @height} = @params
    @color ?= Util.randomColorString()
    @deleted = false
    @partition ?= [0, 0] # which partition we are found in
    @rotation ?= 0

    unless @position?.length
      if @params.parent then @position = @params.parent.position
      else @position = @game.randomPosition()

    @width ?= conf.width
    @height ?= conf.height
    @halfWidth = @width / 2
    @halfHeight = @height / 2

    super @game, @params
    @updatePartition()

  initHandlers: -> @now 'move', => @updatePartition()

  around: (radius) -> @game.around @partition, radius

  distanceTo: (model) -> Util.magnitude @positionDelta model

  delete: ->
    delete @game.partitions[@partition[0]][@partition[1]][@id]
    super arguments[0]

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
      rotation: @rotation
      width: @width
      height: @height

  setState: (state) ->
    super state
    {@deleted, @color, @position, @rotation, @width, @height} = state

  updatePartition: ->
    x = floor @position[0] / @game.partitionSize
    y = floor @position[1] / @game.partitionSize

    return if (@partition[0] is x) and (@partition[1] is y)

    delete @game.partitions[@partition[0]][@partition[1]][@id]
    @game.partitions[x][y][@id] = @
    @partition = [x, y]

  updatePosition: ->
    [a, b] = @position
    x = trunc((@position[0] + @velocity[0] + @game.width) * 100) / 100
    y = trunc((@position[1] + @velocity[1] + @game.height) * 100) / 100
    x %= @game.width
    y %= @game.height

    @position[0] = x
    @position[1] = y
    @emit 'move' unless (a is @position[0]) and (b is @position[1])

  update: ->
    super()
    @updatePosition()

  insertView: -> @view = new ModeledView @game, model: @
