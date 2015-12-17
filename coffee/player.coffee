if require?
  Ship = require './ship'

(module ? {}).exports = class Player
  @TURN_RATE: 0.1
  constructor: (@game, @id, @socket) ->
    return null unless @game and @id
    @ship = new Ship(@)
    @inputs = []

  actions:
    forward: ->
      @ship.gear = 1
    reverse: ->
      @ship.gear = -1
    left: ->
      @ship.position[2] += Player.TURN_RATE
    right: ->
      @ship.position[2] -= Player.TURN_RATE
    brake: ->
      @ship.brake = true

  processInputs: ->
    @control[input].bind(@)() for input in @inputs

  update: ->
    @processInputs()
    @ship.update()
