Util = require './util' if require?
Game = require './game' if require?

(module ? {}).exports = class Frame
  constructor: (@game, @time = 0, @input = [], @tick = 0, @state = {}) ->
    @dt = 0
