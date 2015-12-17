if require?
  Ship = require './ship'

(module ? {}).exports = class Player
  constructor: (@game, @id, @socket) ->
    return null unless @game and @id
    @ship = new Ship(@)
    @inputs = []

  control:
    forward: ->
    reverse: ->
    left: ->
    right: ->
    brake: ->

  processInputs: ->
    @control[input].bind(@)() for input in inputs

  update: ->
    @processInputs()
    @ship.update()
