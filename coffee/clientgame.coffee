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

    @visibleSprites = []
    @mouseSprites = [] # sprites under the mouse
    @stars = @generateStars()
    @player = new Player(@, details.id)
    @player.name = 'Guest'
    @players = [@player]
    @shipState = null
    @ships = []
    # @zoom = 0.2
    @zoom = 1

    @inputs = []

  interpolation:
    reset: (dt) ->
      @interpolation.step = 0
      @interpolation.rate = Client.FRAME_MS / dt

  generateStars: ->
    for state in @initStates
      new Sprite(@, state.position, state.width, state.height, state.color)

  correctPrediction: () ->
    return unless @shipState?.inputSequence
    if @shipState.synced
      if @inputs.length > 20
        @inputs.splice(0, @inputs.length - 20)

      return

    # set the current ship state to the last known server state
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

  processServerData: (data) ->
    inserted = false

    [i, j] = [0, 0]

    # remove our ship from the pile
    for i in [0...data.ships.length]
      if data.ships[i].id == @player.id
        @shipState = data.ships.splice(i, 1)[0]
        break

    i = 0

    # associate each ship state with its previous state
    while i < data.ships.length and j < @ships.length
      state = data.ships[i]
      ship = @ships[j]
      if state.id is ship.id
        ship.setState state.ship
      else if state.id > ship.id
        @ships.splice(j, 1)
        continue
      else
        @ships.push new InterpolatedShip(@player, state.id, state.ship)
        inserted = true

      i++
      j++

    if j > i
      # remove disconnected ships
      @ships.length = i
    else
      # insert new ships
      for j in [i...data.ships.length]
        state = data.ships[j]
        @ships.push new InterpolatedShip(@player, state.id, state.ship)

      # add a vector to the first ship
      if i is 0 and j > 0
        ship = @ships[0]
        console.log 'vector to', ship
        vector = new Vector @, @player.ship, ship, "#00f", 0.8, 2, ship.id
        @player.vectors.push vector

    # sort our list of ships by id
    (@ships.sort (a, b) -> a.id - b.id) if inserted
    @correctPrediction()
    @interpolation.reset.bind(@)(data.tick.dt)

  isMouseInBounds: (bounds) ->
    Util.isInSquareBounds([@client.mouse.x, @client.mouse.y], bounds)

  moveMouse: ->
    prevSprites = @mouseSprites
    @mouseSprites = []

    # Create new list of mouseSprites
    for sprite in @visibleSprites
      continue unless @isMouseInBounds sprite.getBounds()
      @mouseSprites.push(sprite)
      sprite.mouse.hovering = true

      sprite.mouse.enter.bind(sprite)() if sprite.mouse.enter? and not
        ~prevSprites.indexOf(sprite)

    # Remove items from the old list
    for sprite in prevSprites
      # skip items which are still under the mouse
      continue unless ~@mouseSprites.indexOf(sprite) is 0

      sprite.mouse.hovering = false
      sprite.mouse.leave.bind(sprite)() if sprite.mouse.leave?

  updateMouse: ->
    # update mouseSprites list
    @moveMouse() if @client.mouse.moved

    # process click, press and release events
    if @client.mouse.clicked
      for sprite in @mouseSprites when sprite.mouse.click?
        sprite.mouse.click.bind(sprite)(@client.mouse.buttons)

    if @client.mouse.pressed
      for sprite in @mouseSprites when sprite.mouse.press?
        sprite.mouse.press.bind(sprite)(@client.mouse.buttons)

    if @client.mouse.released
      for sprite in @mouseSprites when sprite.mouse.release?
        sprite.mouse.release.bind(sprite)(@client.mouse.buttons)

    # clear mouse related flags
    @client.mouse.moved = false
    @client.mouse.clicked = false
    @client.mouse.pressed = false
    @client.mouse.released = false

  update: ->
    @visibleSprites = []
    ship.update() for ship in @ships
    @interpolation.step++
    super()
    @updateMouse()

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  draw: ->
    @clear()
    sprite.draw() for sprite in @visibleSprites

    @player.ship.draw()
    vector.draw() for vector in @player.vectors

    @c.fillStyle = "#fff"
    @c.font = "14px Courier New"
    @c.fillText 'x:' + @player.ship.position[0].toFixed(0), 0, 18
    @c.fillText 'y:' + @player.ship.position[1].toFixed(0), 80, 18
    @c.fillText 'r:' + @player.ship.position[2].toFixed(2), 160, 18
    @c.fillText 'vx:' + @player.ship.velocity[0].toFixed(0), 260, 18
    @c.fillText 'vy:' + @player.ship.velocity[1].toFixed(0), 340, 18

  step: (time) ->
    super time
    @draw()
