(module ? {}).exports = class Player
  constructor: (@game, @id, @socket) ->
    return null unless @game and @id
    @inputs = []

  processInputs: ->

  updateVelocity: ->

  updateView: -> # override me on the client side

  update: ->
    @processInputs()
    @updateVelocity()
    @updateView()
