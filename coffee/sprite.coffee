if require?
  Util = require './util'

(module ? {}).exports = class Sprite
  @getView: (game, position) ->
    return unless game and position

    limit = [game.width, game.height]
    view = Util.toroidalDelta position, game.viewOffset, limit
    view[2] = position[2]
    view

  @interpolate: (prevState, nextState, rate) ->
    # rate: (ms-per-frame / dt) * step
    # step: the frame number between prevState and nextState
    # dt = nextState.tick.time - prevState.tick.time
    # ex:
    # nextState.tick.time = 1170
    # prevState.tick.time = 1090
    # dt = 1170 - 1090 = 80
    # ms-per-frame = 16
    # rate = 1/20 = 0.05
    # step = 1, 2, 3, 4, or 5, since 80ms has up to five 16ms frames

    velocity: Util.lerp(prevState.velocity, nextState.velocity, rate)
    position: Util.lerp(prevState.position, nextState.position, rate)

  constructor: (@game, @position, @width = 10, @height = 10, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0]
    @visible = false
    @halfWidth = @width / 2
    @halfHeight = @height / 2
    @updateView()

  isInView: ->
    @game.c? and
    (@view[0] >= -@halfWidth) and
    (@view[1] >= -@halfHeight) and
    (@view[0] <= @game.canvas.width + @halfWidth) and
    (@view[1] <= @game.canvas.height + @halfHeight)

  updateView: ->
    return unless @game.c?
    @view = Sprite.getView(@game, @position)
    if @visible = @isInView()
      @game.visibleSprites.push @

  updateVelocity: ->
    @velocity[0] = Math.trunc(@velocity[0] * @game.frictionRate * 100) / 100
    @velocity[1] = Math.trunc(@velocity[1] * @game.frictionRate * 100) / 100

  updatePosition: ->
    @position[0] = (@position[0] + @velocity[0] + @game.width) % @game.width
    @position[1] = (@position[1] + @velocity[1] + @game.height) % @game.height

  update: ->
    @updateVelocity()
    @updatePosition()
    @updateView()

  getState: ->
    position: @position
    velocity: @velocity
    width: @width
    height: @height
    color: @color

  setState: (state) ->
    @position = state.position ? @position
    @velocity = state.velocity ? @velocity
    @width = state.width ? @width
    @height = state.height ? @height
    @color = state.color ? @color

  draw: ->
    return unless @visible
    @game.c.fillStyle = @color
    @game.c.fillRect  @view[0] - @width / 2,
                      @view[1] - @height / 2,
                      @width, @height
