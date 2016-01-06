if require?
  Util = require './util'
  Config = require './config'
  ChildPane = require './childpane'

(module ? {}).exports = class ButtonPane extends ChildPane
  constructor: (@parent, @name, @text, @offset, @click, @params) ->
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

    super @parent, @name, @offset, @width, @height, @colors.background

    @enabled = true

    @click ?= -> console.log 'Hello, World'
    @mouse.enter = => @color = @colors.hover
    @mouse.leave = => @color = @colors.background
    @mouse.press = => @color = @colors.background
    @mouse.release = => @color = @colors.hover
    @mouse.click = => @click()

  draw: ->
    return unless @enabled and @visible
    super()
    c = @game.c
    c.fillStyle = @colors.text
    c.font = @params.font.string
    c.fillText @text, @view[0] + @params.font.offset[0],
      @view[1] + @params.font.offset[1]
