if require?
  Player = require './player'

(module ? {}).exports = class Game
  constructor: (@width = 1025, @height = 1025) ->
    @players = []
    @sprites = []
    @paused = true
    @tick =
      count: 0
      time: 0
      dt: 0

  getOpenPlayerSlot: ->
    for slot in [0..@players.length]
      return slot if not @players[slot]

  newPlayer: (socket) ->
    i = @getOpenPlayerSlot()
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

  draw: ->

  step: (time) ->
    # increment the tick
    @tick.count++
    @tick.dt = time - @tick.time
    @tick.time = time

    @update
    @draw
