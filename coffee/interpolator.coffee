if require?
  Sprite = require './sprite'
  Ship = require './ship'
  Game = require './game'
  Game = require './clientgame'

(module ? {}).exports = class Interpolator
  constructor: (@game)
