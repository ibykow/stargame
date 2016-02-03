Model = require './model' if require?

(module ? {}).exports = class Facility extends Model
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    {@emblemCharacter, @rise} = @params
    @emblemCharacter ?= 'F'
    @rise ?= 3
    @params.width = 9
    @params.height = 9
    super @game, @params

  insertView: ->
    @view = new FacilityView @game,
      model: @
      offset: [@parent.halfWidth + 2, @parent.halfHeight + @rise]
      parent: @parent.view
