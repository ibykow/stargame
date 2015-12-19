if require?
  Sprite = require './sprite'
  Ship = require './ship'
  Game = require './game'

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    super details.game.width, details.game.height, details.game.frictionRate

    { @tick, @initStates } = details.game

    @player = new Player(@, details.player.id, socket)
    @player.name = 'Guest'
    @players = [@player]

    @sprites = @generateSprites()

    @state =
      tick: { count: 0, time: 0, dt: 0 }
      ships: []
      processed: true

    @inputs = []

  generateSprites: ->
    for state in @initStates
      new Sprite(@, state.width, state.height, state.position, state.color)

  correctPrediction: (shipState, tick) ->
    # set the current ship state to the last known server state
    @player.ship.setState(shipState)

    # Make sure our inputs go back far enough
    return unless @inputs.length and tick.count >= @inputs[0].tick.count

    # Match the input with the state
    i = 0
    for i in [0...@inputs.length] when @inputs[i].tick.count < tick.count
      i

    # Remove the old inputs
    @inputs.splice(0, i)

    # Add all the previous inputs together to be played forward
    @player.input = (@inputs.reduce ((p, n) -> p.concat n.input), [])
      .concat @player.input

    console.log 'Rewinding', @player.input.length if @player.input.length

    @player.input.length

  processState: ->
    return if @state.processed
    @state.processed = true

    # find our ship in the state list
    i = 0
    for i in [0...@state.ships.length]
      break if @state.ships[i].id is @player.id

    shipState = @state.ships.splice(i, 1)

    @correctPrediction(shipState, @state.tick) unless not shipState

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

    for state in @state.ships
      position = state.ship.position
      color = state.ship.color
      Ship.draw(@c, position, color) unless state.id is @player.id

  step: (time) ->
    @processState()
    super time
