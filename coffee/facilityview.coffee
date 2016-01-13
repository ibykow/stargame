if require?
  Config = require './config'
  ModeledView = require './modeledview'

pesoChar = Config.common.chars.peso

(module ? {}).exports = class FacilityView extends ModeledView
  draw: ->
    c = @game.c
    c.globalAlpha = 1
    c.fillStyle = @model.color
    c.font = "14px Courier New"
    c.fillText @model.emblemCharacter, @view[0], @view[1]
