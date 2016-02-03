Facility = require './facility' if require?

(module ? {}).exports = class Market extends Facility
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    @params.color = '#FFF'
    @params.emblemCharacter = 'M'
    @params.rise = -8
    super @game, @params
