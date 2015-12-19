if require?
  Util = require './util'

(module ? {}).exports = class Sprite
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
    [vx0, vx1, vy0, vy1] = [
      prevState.velocity[0],
      nextState.velocity[0],
      prevState.velocity[1],
      nextState.velocity[1]
    ]

    vx = (vx1 - vx0) * rate + vx0
    vy = (vy1 - vy0) * (vx - vx0) / (vx1 - vx0) + vy0

    [x0, x1, y0, y1] = [
      prevState.position[0],
      nextState.position[0],
      prevState.position[1],
      nextState.position[1]
    ]


    x = (x1 - x0) * rate + x0
    y = (y1 - y0) * (x - x0) / (x1 - x0) + y0

    # console.log x0, x1, y0, y1, x, y, rate

    [o0, o1] = [prevState.position[2], nextState.position[2]]

    o = (o1 - o0) * rate + o0

    velocity: [vx, vy]
    position: [x, y, o]

  constructor: (@game, @width = 10, @height = 10, @position, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0, 0]

  updateVelocity: ->
    @velocity[0] *= @game.frictionRate
    @velocity[1] *= @game.frictionRate

  updatePosition: ->
    @position[i] += @velocity[i] for i in [0...@position.length]
    @position[0] = (@position[0] + @game.width) % @game.width
    @position[1] = (@position[1] + @game.height) % @game.height

  update: ->
    @updateVelocity()
    @updatePosition()

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
    @game.c.fillStyle = @color
    @game.c.fillRect  @position[0] - @width / 2,
                      @position[1] - @height / 2,
                      @width, @height
