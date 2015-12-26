if require?
  Util = require './util'

[sqrt] = [Math.sqrt]

(module ? {}).exports = class Sprite
  @getView: (game, position) ->
    return unless game and position

    limit = [game.width, game.height]
    view = Util.toroidalDelta position, game.viewOffset, limit
    @collisions = []
    # view[0] *= game.zoom
    # view[1] *= game.zoom
    view[2] = position[2]
    view

  flags:
    isVisible: false
    isRigid: true

  constructor: (@game, @position, @width = 10, @height = 10, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0]
    @magnitude = 0
    @halfWidth = @width / 2
    @halfHeight = @height / 2
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
    return [] unless sprites and @flags.isRigid
    sprites.filter((sprite, i) => sprite.flags.isRigid and @intersects sprite)

  intersects: (sprite) ->
    return false if @ is sprite or not sprite?.getViewBounds
    Util.areSquareBoundsOverlapped @getViewBounds(), sprite.getViewBounds()

  getBoundsFor: (type = 'view') ->
    [[@[type][0] - @halfWidth, @[type][1] - @halfHeight], [@width, @height]]

  getBounds: ->
    @getBoundsFor('position')

  getViewBounds: ->
    @getBoundsFor('view')

  isInView: ->
    w = @halfWidth * @game.zoom
    h = @halfHeight * @game.zoom
    cw = @game.canvas.width
    ch = @game.canvas.height
    @game.c? and (@view[0] >= -w) and (@view[1] >= -h) and
      (@view[0] <= cw + w) and (@view[1] <= ch + h)

  updateView: ->
    return unless @game.c?
    @view = Sprite.getView(@game, @position)
    if @flags.isVisible = @isInView()
      @game.visibleSprites.push @

  updateVelocity: ->
    @velocity[0] = Math.trunc(@velocity[0] * @game.frictionRate * 100) / 100
    @velocity[1] = Math.trunc(@velocity[1] * @game.frictionRate * 100) / 100
    @magnitude = sqrt @velocity.reduce(((sum, v) -> sum + v * v), 0)

  updatePosition: ->
    @position[0] = (@position[0] + @velocity[0] + @game.width) % @game.width
    @position[1] = (@position[1] + @velocity[1] + @game.height) % @game.height

  updateCollisions: ->
    @collisions = @detectCollisions @game.visibleSprites

  update: ->
    @clearFlags()
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
    return unless @flags.isVisible
    @game.c.fillStyle = @color
    # @game.c.fillRect  (@view[0] - @width / 2) * @game.zoom,
    #                   (@view[1] - @height / 2) * @game.zoom,
    #                   @width * @game.zoom, @height * @game.zoom
    @game.c.fillRect  @view[0] - @width * @game.zoom / 2,
                      @view[1] - @height * @game.zoom / 2,
                      @width * @game.zoom, @height * @game.zoom
