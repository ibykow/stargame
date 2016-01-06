if require?
  Util = require './util'
  Config = require './config'
  Sprite = require './sprite'

(module ? {}).exports = class PaneButton extends Pane
  constructor: (@parent, @name, @text, @params, @offset, @click) ->
    return unless @parent

    @params ?=
      width: 50
      height: 30
      colors:
        background: '#0a0'
        hover: '#5a5'
        text: '#fff'
      font:
        string: '12px Courier New'
        offset: [12, 18, 0]

    { @width, @height, @colors } = @params

    super @parent.game, @parent.view, @width, @height, @colors.background

    @parent.adopt @, @name
    @enabled = true
    @visible = true
    @offset ?= [0, 0]
    @click ?= -> console.log 'Hello, World'

    @mouse.enter = => @color = @colors.hover
    @mouse.leave = => @color = @colors.background
    @mouse.press = => @color = @colors.background
    @mouse.release = => @color = @colors.hover
    @mouse.click = => @click()

  updateView: ->
    @view[0] = @parent.view[0] + @offset[0]
    @view[1] = @parent.view[1] + @offset[1]

  draw: ->
    return unless @enabled and @visible
    super()
    c = @game.c
    c.fillStyle = @colors.text
    c.font = @params.font.string
    c.fillText @text, @view[0] + @params.font.offset[0],
      @view[1] + @params.font.offset[1]
