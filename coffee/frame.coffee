Util = require './util' if require?
Tick = require './tick' if require?

(module ? {}).exports = class Frame
  constructor: (@game, time = 0, previousFrame = {}, @inputs = []) ->
    return unless @game

    @tick = new Tick(time, previousFrame.tick)
    @state =
      width: @game.width
      height: @game.height
      players: []
      sprites: []
