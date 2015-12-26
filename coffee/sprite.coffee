if require?
  Util = require './util'

(module ? {}).exports = class Sprite
  @getView: (game, position) ->
    return unless game and position

    limit = [game.width, game.height]
    view = Util.toroidalDelta position, game.viewOffset, limit
    @collided = []
    # view[0] *= game.zoom
    # view[1] *= game.zoom
    view[2] = position[2]
    view

  constructor: (@game, @position, @width = 10, @height = 10, @color) ->
    return null unless @game
    @position ?= @game.randomPosition()
    @color ?= Util.randomColorString()
    @velocity = [0, 0]
    @visible = false
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

  filterCollided: (sprites = @game.visibleSprites) ->
    return [] unless sprites
    sprites.filter((sprite) => @isCollidedWith sprite)

  isCollidedWith: (sprite) ->
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
    if @visible = @isInView()
      @game.visibleSprites.push @

  updateVelocity: ->
    @velocity[0] = Math.trunc(@velocity[0] * @game.frictionRate * 100) / 100
    @velocity[1] = Math.trunc(@velocity[1] * @game.frictionRate * 100) / 100

  updatePosition: ->
    @position[0] = (@position[0] + @velocity[0] + @game.width) % @game.width
    @position[1] = (@position[1] + @velocity[1] + @game.height) % @game.height

  updateCollided: ->
    @collided = @filterCollided()

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
    # @game.c.fillRect  (@view[0] - @width / 2) * @game.zoom,
    #                   (@view[1] - @height / 2) * @game.zoom,
    #                   @width * @game.zoom, @height * @game.zoom
    @game.c.fillRect  @view[0] - @width * @game.zoom / 2,
                      @view[1] - @height * @game.zoom / 2,
                      @width * @game.zoom, @height * @game.zoom
