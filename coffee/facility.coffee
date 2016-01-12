Model = require './model' if require?

(module ? {}).exports = class Facility extends Model
  constructor: (@game, @params) ->
    return unless @game? and @params?.parent
    {@emblemCharacter} = @params
    @emblemCharacter ?= 'F'
    @params.width = 9
    @params.height = 9
    super @game, @params
