if require?
  Sprite = require './sprite'
  Ship = require './ship'
  Game = require './game'
  Client = require './client'

[floor, max] = [Math.floor, Math.max]

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    super details.game.width, details.game.height, details.game.frictionRate

    { @tick, @starStates } = details.game

    @visibleSprites = []
    @mouseSprites = [] # sprites under the mouse
    @stars = @generateStars()
    @player = new Player(@, details.id, socket)
    @player.name = 'Guest'
    @players = [@player]
    @ships = []
    @history = new RingBuffer ClientGame.HISTORY_LEN
    @inputSequence = 1
    @lastVerifiedInputSequence = 0

  interpolation:
    reset: (dt) ->
      @step = 0
      @rate = Client.FRAME_MS / dt

  generateStars: ->
    for state in @starStates
      new Sprite(@, state.position, state.width, state.height, state.color)

  correctPrediction: ->
    inputLog = @player.logs['input']
    serverInputSequence = @shipState?.inputSequence

    return unless serverInputSequence > @lastVerifiedInputSequence
    @lastVerifiedInputSequence = serverInputSequence

    # Remove logged inputs prior to the server's input sequence
    # We won't be using those for anything
    inputLog.purge((entry) -> entry.sequence < serverInputSequence)

    # do the correction only if we're out of sync with the server
    clientState = inputLog.remove()?.ship.position
    serverState = @shipState.ship.position
    return unless Util.vectorDeltaExists(clientState, serverState)

    # set the current ship state to the last known (good) server state
    @player.ship.setState(serverState)

    inputLog.remove()

    # rewind and replay
    for entry in inputLog.toArray()
      @player.inputs = entry.inputs
      @player.update()

  processServerData: (data) ->
    # console.log 'processing server state'
    [inserted, i, j, stateLog] = [false, 0, 0, @player.logs['state']]

    # remove our ship from the pile
    for i in [0...data.ships.length]
      if data.ships[i].id == @player.id
        # console.log 'found our ship'
        @shipState = data.ships.splice(i, 1)[0]
        break

    # reset the index (ie. leave this here)
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

    # remove disconnected ships
    if j > i
      @ships.length = i

    # or insert new ships
    else
      for j in [i...data.ships.length]
        state = data.ships[j]
        @ships.push new InterpolatedShip(@player, state.id, state.ship)

      # add an arrow to the first ship
      if i is 0 and j > 0
        ship = @ships[0]
        console.log 'arrow to', ship
        arrow = new Arrow @, @player.ship, ship, "#00f", 0.8, 2, ship.id
        @player.arrows.push arrow

    # if a new player has entered, sort our list of ships by id
    (@ships.sort (a, b) -> a.id - b.id) if inserted

    # remove old states from the log
    stateLog.purge((entry) -> entry.sequence < data.tick.count)

    @correctPrediction()
    @interpolation.reset(data.tick.dt)

  isMouseInBounds: (bounds) ->
    Util.isInSquareBounds([@client.mouse.x, @client.mouse.y], bounds)

  moveMouse: ->
    prevSprites = @mouseSprites
    @mouseSprites = []

    # Create new list of mouseSprites
    for sprite in @visibleSprites
      continue unless @isMouseInBounds sprite.getViewBounds()
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
    @updateMouse()
    star.update() for star in @stars
    super()
    @player.update()
    @player.updateArrows()

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  drawHUD: ->
    @c.fillStyle = "#fff"
    @c.font = "14px Courier New"
    @c.fillText 'x:' + @player.ship.position[0].toFixed(0), 0, 18
    @c.fillText 'y:' + @player.ship.position[1].toFixed(0), 80, 18
    @c.fillText 'r:' + @player.ship.position[2].toFixed(2), 160, 18
    @c.fillText 'vx:' + @player.ship.velocity[0].toFixed(0), 260, 18
    @c.fillText 'vy:' + @player.ship.velocity[1].toFixed(0), 340, 18

  draw: ->
    @clear()
    sprite.draw() for sprite in @visibleSprites
    @player.ship.draw()
    arrow.draw() for arrow in @player.arrows
    @drawHUD()

  updateServer: (inputs) ->
    entry =
      sequence: @inputSequence
      ship: @player.ship.getState()
      inputs: inputs

    @player.logs['input'].insert entry
    @player.socket.emit 'input', entry
    @inputSequence++

  step: (time) ->
    inputs = @client.getMappedInputs()
    @player.inputs = inputs
    super time
    @updateServer(inputs)
    @draw()
