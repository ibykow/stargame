if require?
  Util = require './util'
  Config = require './config'

{abs, floor, sqrt, round, trunc} = Math
rnd = Math.random
isarr = Array.isArray

(module ? {}).exports = class Button extends ComponentView
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    {@name, @text, @font, @enabled} = @params
    @enabled ?= true
    @name ?= 'myButton'
    @text ?= 'OK'
    @font ?=
      string: '12px Courier New'
      offset: [5, 5]
    super @game, @params

    @immediate 'mouse-click', => console.log 'Clicked', @name

  update: ->
    @view = [ @parent.view[0] + @offset[0],
              @parent.view[1] + @offset[1],
              @parent.view[2] ]

    # if @hovering then @color = @params.colors.hover
    # else @color = @params.colors.leave

  draw: ->
    return unless @enabled and @visible
    super()
    @game.c.fillStyle = @colors.text
    @game.c.font = @params.font.string
    @game.c.fillText @text,
      @view[0] + @font.offset[0], @view[1] + @font.offset[1]
