# Pane: View only sprite
if require?
  Util = require './util'
  Config = require './config'
  Sprite = require './sprite'

{abs, floor, sqrt, round, trunc} = Math
rnd = Math.random
isarr = Array.isArray

(module ? {}).exports = class Pane extends Sprite
  constructor: (@game, @view, @width, @height, @color, @visible = false,
  @alpha, @resize = ->) ->
    return unless @game
    super @game, @view, @width, @height, @color, @alpha
    if @visible then @open() else @close()
    @game.on 'resize', @resize.bind @
    @mouse.leave = => @close()

  open: -> @visible = @flags.isVisible = true
  close: -> @visible = @flags.isVisible = false
  getViewBounds: -> [[@view[0], @view[1]], [@width, @height]]
  update: -> @game.visibleSprites.push @ unless @visible
  draw: ->
    c = @game.c
    c.fillStyle = @color
    c.globalAlpha = @alpha
    c.fillRect @view[0], @view[1], @width, @height
    c.globalAlpha = 1
