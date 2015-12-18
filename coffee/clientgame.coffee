if require?
  Sprite = require './sprite'
  Ship = require './ship'
  Game = require './game'

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    { @width, @height, @frictionRate, @tick, @states } = details.game
    super @width, @height, @frictionRate

    @player = new Player(@, details.player.id, socket)
    @player.name = 'Guest'
    @players = [@player]

    @sprites = @generateSprites()
    @state = {}

  generateSprites: ->
    for state in @states
      new Sprite(@, state.width, state.height, state.position, state.color)

  updateFromState: ->
    return unless @state.ships
    myShip = (@state.ships.filter (s) =>
      return s.id == @player.id)[0].ship

    @player.ship.position = myShip.position
    @player.ship.velocity = myShip.velocity

  update: ->
    @updateFromState() if @state
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

    if @state and @state.ships
      for state in @state.ships
        position = state.ship.position
        color = state.ship.color
        Ship.draw(@c, position, color) unless state.id is @player.id
