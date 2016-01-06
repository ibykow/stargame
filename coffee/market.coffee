Facility = require './facility' if require?
(module ? {}).exports = class Market extends Facility
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    @params.emblemCharacter = 'M'
    @params.color = '#FFF'
    super @game, @params

  insertView: ->
    params = offset: [@parent.halfWidth + 2, 0]
    @view = new FacilityView @game, params
