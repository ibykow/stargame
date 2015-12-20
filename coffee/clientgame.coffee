if require?
  Sprite = require './sprite'
  Ship = require './ship'
  Game = require './game'
  Client = require './client'

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    super details.game.width, details.game.height, details.game.frictionRate

    { @tick, @initStates } = details.game

    @player = new Player(@, details.id)
    @player.name = 'Guest'
    @players = [@player]
    @loops = []

    @sprites = @generateSprites()

    @prevState = null
    @nextState = null
    @shipState = null
    @inputs = []

  interpolation:
    reset: ->
      @interpolation.step = 0
      @interpolation.rate = Client.FRAME_MS / @nextState.tick.dt
    step: 0
    rate: 0

  generateSprites: ->
    for state in @initStates
      new Sprite(@, state.width, state.height, state.position, state.color)

  correctPrediction: () ->
    return unless @shipState?.inputSequence
    if @shipState.synced
      if @inputs.length > 20
        @inputs.splice(0, @inputs.length - 20)

      return

    # set the current ship state to the last known server state
    # Sprite.interpolate(@player.ship, @shipState.ship, 0.9)
    @player.ship.setState(@shipState.ship)

    # Match the input with the state
    i = 0
    for i in [0...@inputs.length]
      if not @inputs[i].inputSequence?
        console.log 'invalid inputEntry'
      break if @inputs[i].inputSequence >= @shipState.inputSequence

    # Remove the old inputs
    @inputs.splice(0, i)

    if @inputs.length
      temp = @inputs.map (e) -> e.input
      if Array.isArray(@player.inputs[0]) or (@player.inputs.length is 0)
        @player.inputs = temp.concat(@player.inputs)
      else
        @player.inputs = @player.inputs.push temp


  processStates: ->
    @nextState.processed = true

    [i, j] = [0, 0]

    # associate each ship state with its previous state
    while i < @nextState.ships.length

      # remove our ship from the list
      if @nextState.ships[i].id == @player.id
        @shipState = @nextState.ships.splice(i, 1)[0]
        continue

      return if j >= @prevState.ships.length

      # associate the ship state with its previous state
      if @nextState.ships[i].id is @prevState.ships[j].id
        @nextState.ships[i].prevState =
          id: @prevState.ships[j].id
          ship: @prevState.ships[j].ship
        # @nextState.ships[i].prevState = null
      else if @nextState.ships[i].id > @prevState.ships[j].id
        j++
        continue
      i++

    @correctPrediction()

  update: ->
    super()
    @draw()

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  draw: ->
    @clear()
    sprite.draw() for sprite in @sprites

    @player.ship.draw()

    for state in @nextState.ships
      if not state.prevState
        Ship.draw(@c, state.ship.position, state.ship.color)
        continue

      nextState = state.ship
      prevState = state.prevState.ship
      rate = @interpolation.rate * @interpolation.step
      @interpolation.step++

      inter = Sprite.interpolate.bind(@)(prevState, nextState, rate)
      color = state.ship.color

      Ship.draw(@c, inter.position, color)
