if require?
  Config = require './config'
  ModeledView = require './modeledview'

(module ? {}).exports = class FacilityView extends ModeledView
  draw: ->
    c = @game.c
    c.globalAlpha = 1
    c.fillStyle = @model.color
    c.font = "14px Courier New"
    c.fillText @model.emblemCharacter,
      @offset[0] + @parent.offset[0], @offset[1] + @parent.offset[1]

  update: -> @game.visibleViews.push @ if @visible = @parent.visible
