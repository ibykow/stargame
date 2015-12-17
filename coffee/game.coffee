if require?
  Util = require './util'
  Player = require './player'

(module ? {}).exports = class Game
  constructor: (@width = 1024, @height = 600, @frictionRate = 0.95) ->
    @players = []
    @sprites = []
    @paused = true
    @tick =
      count: 0
      time: 0
      dt: 0

  randomPosition: ->
    [Util.randomInt(0, @width), Util.randomInt(0, @height), 0]

  newPlayer: (socket) ->
    i = Util.findEmptySlot(@players)
    @players[i] = new Player(@, i + 1, socket)

  removePlayer: (p) ->
    return unless p and p.id
    @players[p.id - 1] = null

    # remove empty slots from end of @players list
    @players.length-- while @players.length and
    not @players[@players.length - 1]

  update: ->
    player.update() for player in @players
    sprite.update() for sprite in @sprites

  step: (time) ->
    # increment the tick
    @tick.count++
    @tick.dt = time - @tick.time
    @tick.time = time
    @update()
