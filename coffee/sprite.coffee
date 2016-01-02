if require?
  Config = require './config'
  Util = require './util'
  Eventable = require './eventable'

[abs, isarr, sqrt, round, trunc] = [Math.abs, Array.isArray, Math.sqrt,
  Math.round, Math.trunc]

(module ? {}).exports = class Sprite extends Eventable
  constructor: (@game, @position, @width = 10, @height = 10, @color) ->
    super @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0]
    @magnitude = 0
    @halfWidth = @width / 2
    @halfHeight = @height / 2
    @children = {}
    @bulletCollisions = []
    @mouse =
      hovering: false
      enter: ->
        console.log 'Planning on staying long?'
      leave: ->
        console.log "Please don't leave me!"
      click: ->
        console.log 'You clicked me!'

    @flags =
      isVisible: true
      isRigid: true
      isDeleted: false

    @updateView()

  # (Re)places child and force updates child's parent
  adopt: (child, name) ->
    return unless child
    name ?= child.constructor?.name or 'annie'
    @children[name] = child
    child.parent = @

  distanceTo: (sprite) ->
    Util.magnitude @positionDelta(sprite)

  positionDelta: (sprite) ->
    return [0, 0] unless sprite?.position.length
    Util.toroidalDelta @position, sprite.position, @game.toroidalLimit

  clearFlags: -> @flags[k] = false for k of @flags

  handleBulletImpact: (b) ->
    return unless @flags.isRigid and b?.damage
    b.life = 0

  detectCollisions: (sprites = @game.visibleSprites, maxIndex) ->
    # primitive, and inefficient collision detection
    # TODO Consider adding a quadtree implementation to handle big
    # collections such as stars, and bullets, etc.
    # eg. if QuadTree.isQuad(sprites) sprites.detect(@) else ...
    return [] unless isarr(sprites) and @flags.isRigid
    sprites.filter (sprite, i) => sprite.flags.isRigid and @intersects sprite

  intersects: (sprite) ->
    return false if @ is sprite or not sprite?.position
    delta = @positionDelta sprite
    (abs(delta[0]) <= @halfWidth + sprite.halfWidth) and
    (abs(delta[1]) <= @halfHeight + sprite.halfHeight)

  getBoundsFor: (type = 'view') ->
    [[@[type][0] - @halfWidth, @[type][1] - @halfHeight], [@width, @height]]

  getBounds: -> @getBoundsFor('position')

  getViewBounds: -> @getBoundsFor('view')

  getState: ->
    # We ignore @magnitude (ie. independent variables only).
    childStates = {}
    childStates[type] = child.getState() for type, child of @children

    Object.assign super(),
      position: @position.slice()
      velocity: @velocity.slice()
      width: @width
      height: @height
      color: @color
      flags: @flags
      children: childStates

  setState: (state) ->
    super state
    {@position, @velocity, @width, @height, @color, @flags, @children} = state

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
    @magnitude = sqrt @velocity.reduce ((sum, v) -> sum + v * v), 0

  updatePosition: ->
    x = trunc((@position[0] + @velocity[0] + @game.width) * 100) / 100
    y = trunc((@position[1] + @velocity[1] + @game.height) * 100) / 100
    z = trunc (((@position[2] + Util.TWO_PI) % Util.TWO_PI) * 100) / 100
    x %= @game.width
    y %= @game.height

    @position[0] = x
    @position[1] = y

  updateChildren: ->
    child.update() for type, child of @children

  update: ->
    @updateVelocity()
    @updatePosition()
    @updateView()
    @updateChildren()

  draw: ->
    return unless @flags.isVisible
    @game.c.fillStyle = @color
    @game.c.fillRect  @view[0] - @halfWidth, @view[1] - @halfHeight,
                      @width, @height

    child.draw(@view) for type, child of @children
