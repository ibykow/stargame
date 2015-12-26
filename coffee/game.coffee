if require?
  Util = require './util'
  Player = require './player'

(module ? {}).exports = class Game
  constructor: (@width = 1 << 8, @height = 1 << 8, @frictionRate = 0.96) ->
    @players = []
    @stars = []
    @sprites = []
    @paused = true
    @viewOffset = [0, 0] # userd by sprites
    @tick =
      count: 0
      time: 0
      dt: 0

  randomPosition: ->
    [Util.randomInt(0, @width), Util.randomInt(0, @height), 0]

  newPlayer: (socket, position) ->
    i = Util.findEmptySlot @players
    @players[i] = new Player(@, i + 1, socket, position)

  removePlayer: (p) ->
    return unless p and p.id
    @players[p.id - 1] = null

    # remove empty slots from end of @players list
    @players.length-- while @players.length and
    not @players[@players.length - 1]

  update: ->
    star.update() for star in @stars
    sprite.update() for sprite in @sprites
    player.update() for player in @players when player

  step: (time) ->
    # increment the tick
    @tick.dt = time - @tick.time
    @tick.time = time
    @tick.count++
    @update()
