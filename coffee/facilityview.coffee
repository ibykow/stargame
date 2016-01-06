if require?
  Config = require './config'
  View = require './view'

pesoChar = Config.common.chars.peso

(module ? {}).exports = class FacilityView extends View
  draw: -> # we don't get called unless the parent is visible
    c = @game.c
    c.globalAlpha = 1
    c.fillStyle = @model.color
    c.font = "14px Courier New"
    c.fillText @model.emblemCharacter, @view[0], @view[1]
