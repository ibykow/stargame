Facility = require './facility' if require?
(module ? {}).exports = class Market extends Facility
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    @params.emblemCharacter = 'M'
    @params.color = '#FFF'
    super @game, @params

  insertView: ->
    @view = new FacilityView @game,
      offset: [@parent.halfWidth + 2, 0]
      model: @
