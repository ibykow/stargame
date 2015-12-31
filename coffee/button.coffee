if require?
  Util = require './util'
  Config = require './config'
  Sprite = require './sprite'

[abs, floor, isarr, sqrt, rnd, round, trunc] = [Math.abs, Math.floor,
  Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc]

cfg = Config.common.button

(module ? {}).exports = class Button extends Sprite
  constructor: (@parent, name, click, @text = 'OK', @params = cfg) ->
    return unless @parent

    { width, height, colors, } = @params

    super @parent.game, @parent.position, width, height, colors.background

    @parent.adopt @, name

    click = click ? -> console.log 'Hello, World'

    @mouse.click = =>
      @color = colors.click
      click @

    @enabled = @params.default.enabled

  updatePosition: ->
    @position = [
      @parent.position[0] + @params.offset[0],
      @parent.position[1] + @params.offset[1],
      @parent.position[2]
    ]

  update: ->
    super()
    if @mouse.hovering
      @color = @params.colors.hover
    else
      @color = @params.colors.background

  isInView: ->
    @enabled and super()

  draw: -> # we don't get called unless the parent is visible
    return unless @enabled
    xoff = -@halfWidth
    yoff = -@halfHeight
    @game.c.fillStyle = @color
    @game.c.fillRect @view[0] + xoff, @view[1] + yoff, @width, @height
    @game.c.fillStyle = @params.colors.text
    @game.c.font = @params.font.string
    @game.c.fillText @text, @view[0] + @params.font.offset[0] + xoff,
      @view[1] + @params.font.offset[1]

    # @game.c.fillText @text, @view[0] + @params.font.offset[0],
    #   @view[0] + @params.font.offset[1]
