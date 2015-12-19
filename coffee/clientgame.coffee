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

    @player = new Player(@, details.player.id, socket)
    @player.name = 'Guest'
    @players = [@player]
    @loops = []

    @sprites = @generateSprites()

    @prevState = null
    @nextState = null
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

  correctPrediction: (shipState, tick) ->
    # set the current ship state to the last known server state
    @player.ship.setState(shipState)

    # Make sure our inputs go back far enough
    return unless @inputs.length and tick.count >= @inputs[0].tick.count

    # Match the input with the state
    while i < @inputs.length
      break if @inputs[i].tick.count >= tick.count

    # Remove the old inputs
    @inputs.splice(0, i)

    # Add all the previous inputs together to be played forward
    @player.input = (@inputs.reduce ((p, n) -> p.concat n.input), [])
      .concat @player.input

    # console.log 'Rewinding', @player.input.length if @player.input.length

    @player.input.length

  processStates: ->
    return if @nextState.processed
    @nextState.processed = true

    [i, j, shipState] = [0, 0, null]

    loops = 0
    # associate each ship state with its previous state
    # console.log 'intersecting', @nextState.ships.length, @prevState.ships.length
    while i < @nextState.ships.length
      loops++
      # remove our ship from the list
      # console.log i, j, @nextState.ships[i], @nextState.ships[j]
      # console.log 'setting', @nextState.ships[i].id, 'and', @prevState.ships[j]

      if @nextState.ships[i].id == @player.id
        # console.log 'found my ship'
        shipState = @nextState.ships.splice(i, 1)
        continue

      return if j >= @prevState.ships.length

      # associate the ship state with its previous state
      if @nextState.ships[i].id is @prevState.ships[j].id
        @nextState.ships[i].prevState =
          id: @prevState.ships[j].id
          ship: @prevState.ships[j].ship
        # @nextState.ships[i].prevState = null
        # console.log 'associated:', @nextState.ships[i].prevState, @prevState.ships[j]
      else if @nextState.ships[i].id > @prevState.ships[j].id
        j++
        continue

      i++

    @correctPrediction(shipState, @nextState.tick) unless not shipState

    @loops.push(loops)

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

    # console.log 'me:', @tick.count, @nextState.tick.count, @player.ship.position
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
      # console.log 'drawing', nextState, prevState, inter, rate
      Ship.draw(@c, inter.position, color)
