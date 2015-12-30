if require?
  Util = require './util'

[abs, isarr, sqrt, round, trunc] = [Math.abs, Array.isArray, Math.sqrt,
  Math.round, Math.trunc]

(module ? {}).exports = class Sprite
  flags:
    isVisible: false
    isRigid: true
    isDeleted: false

  constructor: (@game, @position, @width = 10, @height = 10, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0]
    @magnitude = 0
    @halfWidth = @width / 2
    @halfHeight = @height / 2
    @bulletCollisions = []
    @mouse =
      hovering: false
      enter: ->
        console.log 'Planning on staying long?'
      leave: ->
        console.log "Please don't leave me!"
      click: ->
        console.log 'You clicked me!'

    @updateView()

  clearFlags: ->
    for k in @flags
      @flags[k] = false

  detectCollisions: (sprites = @game.visibleSprites, maxIndex) ->
    # primitive, and inefficient collision detection
    # TODO Consider adding a quadtree implementation to handle big
    # collections such as stars, and bullets, etc.
    # eg. if QuadTree.isQuad(sprites) sprites.detect(@) else ...
    return [] unless isarr(sprites) and @flags.isRigid
    sprites.filter((sprite, i) => sprite.flags.isRigid and @intersects sprite)

  intersects: (sprite) ->
    return false if @ is sprite or not sprite?.position
    delta = Util.toroidalDelta(@position, sprite.position, @game.toroidalLimit)
    # console.log 'delta', delta
    # console.log 'delta', delta
    (abs(delta[0]) <= @halfWidth + sprite.halfWidth) and
    (abs(delta[1]) <= @halfHeight + sprite.halfHeight)

  getBoundsFor: (type = 'view') ->
    [[@[type][0] - @halfWidth, @[type][1] - @halfHeight], [@width, @height]]

  getBounds: ->
    @getBoundsFor('position')

  getViewBounds: ->
    @getBoundsFor('view')

  isInView: ->
    w = @halfWidth
    h = @halfHeight
    cw = @game.canvas.width
    ch = @game.canvas.height
    @game.c? and (@view[0] >= -w) and (@view[1] >= -h) and
      (@view[0] <= cw + w) and (@view[1] <= ch + h)

  updateView: ->
    @view = Util.toroidalDelta @position, @game.viewOffset, @game.toroidalLimit
    @view[2] = @position[2]

    if @flags.isVisible = @isInView()
      @game.visibleSprites.push @

  updateVelocity: ->
    @velocity[0] = trunc(@velocity[0] * @game.frictionRate * 100) / 100
    @velocity[1] = trunc(@velocity[1] * @game.frictionRate * 100) / 100
    @magnitude = sqrt @velocity.reduce(((sum, v) -> sum + v * v), 0)

  updatePosition: ->
    x = round((@position[0] + @velocity[0] + @game.width) % @game.width)
    y = round((@position[1] + @velocity[1] + @game.height) % @game.height)

    @position[0] = x
    @position[1] = y

  updateBulletCollisions: ->
    @bulletCollisions = @detectCollisions @game.bullets

  update: ->
    @clearFlags()
    @updateVelocity()
    @updatePosition()
    @updateView()

  getState: ->
    # We ignore @magnitude and flags.
    # ie. independent variables only
    position: @position.slice()
    velocity: @velocity.slice()
    width: @width
    height: @height
    color: @color
    flags: @flags

  setState: (state) ->
    @position = state.position
    @velocity = state.velocity
    @width = state.width
    @height = state.height
    @color = state.color
    flags: state.flags

  draw: ->
    return unless @flags.isVisible
    @game.c.fillStyle = @color
    @game.c.fillRect  @view[0] - @halfWidth, @view[1] - @halfHeight,
                      @width, @height
