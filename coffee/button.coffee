if require?
  Util = require './util'
  Config = require './config'

{abs, floor, sqrt, round, trunc} = Math
rnd = Math.random
isarr = Array.isArray

(module ? {}).exports = class Button extends ComponentView
  constructor: (@game, @params) ->
    return unless @game?
    {@name, @text, @font} = @params
    @name ?= 'myButton'
    @text ?= 'OK'
    @font ?=
      string: '12px Courier New'
      offset: [5, 5]
    super @game, @params

    @now 'mouse-click', => console.log 'Clicked', @name

  draw: ->
    super()
    @game.c.fillStyle = @colors.text
    @game.c.font = @params.font.string
    @game.c.fillText @text,
      @offset[0] + @font.offset[0], @pffset[1] + @font.offset[1]
    @restore()
