global = global or window

if require?
  Sprite = require './sprite'
  GasStation = require './gasstation'
  Ship = require './ship'
  Game = require './game'
  Player = require './player'
  Client = require './client'
  Pager = require './pager'

[isarr, floor, max] = [Array.isArray, Math.floor, Math.max]
pesoChar = Config.common.chars.peso

Player::die = -> @ship.isDeleted = true
Sprite.updatePosition = ->
Sprite.updateVelocity = ->

(module ? {}).exports = class ClientGame extends Game
  constructor: (details, @canvas, @c, socket) ->
    return unless details
    super details.game.width, details.game.height, details.game.frictionRate

    { @tick, @starStates } = details.game

    @visibleSprites = []
    @mouseSprites = [] # sprites under the mouse
    @collisionSpriteLists.stars = @stars = @generateStars()
    @player = new Player(@, details.id, socket)
    @player.name = 'Guest'
    @players = [@player]
    @lastVerifiedInputSequence = 0
    @collisionSpriteLists.myShip = [@player.ship]
    @pager = new Pager @
    @page = @pager.page.bind @pager

  interpolation:
    reset: (dt) ->
      @step = 0
      @rate = Config.common.msPerFrame / dt

  # quick and dirty
  testPager: ->
    @pager.page('Hello, World Number ' + i) for i in [1..20]
    console.log @pager.buffer

  generateStars: ->
    for state in @starStates
      s = new Sprite @, state.position, state.width, state.height, state.color
      # console.log s.children
      for type, childState of state.children
        # console.log 'adding child', global[type].name, childState
        global[type].fromState s, childState
      s

  removeShip: (id) ->
    for i in [0...@ships.length]
      if @ships[i].player.id == id
        @ships[i].flags.isDeleted = true
        @ships.splice i, 1
        break

  correctPrediction: ->
    inputLog = @player.logs['input']
    serverInputSequence = @shipState?.inputSequence
    serverState = @shipState.ship

    return unless serverInputSequence > @lastVerifiedInputSequence

    @lastVerifiedInputSequence = serverInputSequence

    @player.ship.health = serverState.health

    # Remove logged inputs prior to the server's input sequence
    # We won't be using those for anything
    inputLog.purge((entry) -> entry.sequence <= serverInputSequence)

    # do the correction only if we're out of sync with the server
    logEntry = inputLog.remove()
    clientPosition = logEntry?.ship.position
    serverPosition = serverState.position

    if serverState.health < logEntry?.ship.health
      @player.ship.health = serverState.health
    # console.log 'correct', serverPosition, 'vs', clientPosition
    return unless Util.vectorDeltaExists(clientPosition, serverPosition)

    # console.log 'correcting ship state'
    # console.log logEntry?.sequence, clientPosition
    # console.log serverInputSequence, serverPosition
    # console.log Util.toroidalDelta clientPosition, serverPosition,
    #   @toroidalLimit

    # set the current ship state to the last known (good) server state
    @player.ship.setState(serverState)

    entries = inputLog.toArray().slice()
    # console.log 'input log', inputLog.tail, inputLog.head, entries.length
    inputLog.reset()
    # rewind and replay
    for entry in entries
      # console.log 'entry', entry
      @player.inputSequence = entry.sequence
      @player.inputs = entry.inputs
      @player.update()

  processServerData: (data) ->
    [inserted, i, j, stateLog] = [false, 0, 0, @player.logs['state']]

    # console.log 'bullets', data.bullets
    @bullets = (Bullet.fromState @, bullet for bullet in data.bullets)

    # remove our ship from the pile
    for i in [0...data.ships.length]
      if data.ships[i].id == @player.id
        # splicing sucks
        @shipState = data.ships.splice(i, 1)[0]
        break

    # reset the index (ie. leave this here)
    i = 0

    # associate each ship state with its previous state
    while i < data.ships.length and j < @ships.length
      state = data.ships[i]
      ship = @ships[j]
      if state.id is ship.player.id
        ship.setState state.ship
      else if state.id > ship.player.id
        @ships.splice(j, 1)
        continue
      else
        p =
          id: state.id
          game: @
        @ships.push new InterpolatedShip(p, state.ship)
        @collisionSpriteLists.ships = @ships
        inserted = true

      i++
      j++

    if j > i # remove disconnected ships
      @ships.length = i
    else # or insert new ships
      for j in [i...data.ships.length]
        state = data.ships[j]
        p =
          id: state.id
          game: @
        @ships.push new InterpolatedShip(p, state.ship)
        @collisionSpriteLists.ships = @ships

      # add an arrow to the first ship
      if i is 0 and j > 0
        ship = @ships[0]
        console.log 'arrow to', ship
        @player.arrowTo ship, ship.player.id

    # if a new player has entered, sort our list of ships by id
    (@ships.sort (a, b) -> a.id - b.id) if inserted

    # remove old states from the log
    stateLog.purge((entry) -> entry.sequence < data.tick.count)

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
    super()
    star.update() for star in @stars
    ship.update() for ship in @ships
    @interpolation.step++
    @correctPrediction()
    @player.update()
    @player.updateArrows()

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Config.client.colors.background.default
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  drawFuel: (x, y) ->
    if not @player.ship.fuel
      @c.fillStyle = "#f00"
      @c.font = "Bold 12px Courier"
      @c.fillText "NO GAS", x, y + 10
      return

    remain = @player.ship.fuel / @player.ship.fuelCapacity
    redness = floor remain * 0xFF

    @c.fillStyle = "rgba(" + (0xFF - redness) + "," + redness + "," + 0 + ",1)"

    @c.strokeStyle = "#fff"
    @c.lineWidth = 2
    @c.fillRect x, y, floor(remain * 30), 9
    @c.strokeRect x, y, 30, 9

  drawHUD: ->
    @c.fillStyle = "#fff"
    @c.font = "14px Courier New"
    @c.fillText 'x:' + @player.ship.position[0].toFixed(0), 0, 10
    @c.fillText 'y:' + @player.ship.position[1].toFixed(0), 80, 10
    @c.fillText 'x:' + @player.ship.view[0].toFixed(0), 0, 20
    @c.fillText 'y:' + @player.ship.view[1].toFixed(0), 80, 20
    @c.fillText 'x:' + @client.mouse.x.toFixed(0), 0, 30
    @c.fillText 'y:' + @client.mouse.y.toFixed(0), 80, 30
    @c.fillText 'r:' + @player.ship.position[2].toFixed(2), 160, 10
    @c.fillText 'vx:' + @player.ship.velocity[0].toFixed(0), 260, 10
    @c.fillText 'vy:' + @player.ship.velocity[1].toFixed(0), 340, 10
    @c.fillText 'hp:' + @player.ship.health, 420, 10
    @c.fillText 'cash:' + pesoChar + @player.cash.toFixed(2), 540, 10
    @drawFuel 480, 2

  draw: ->
    @clear()
    sprite.draw() for sprite in @visibleSprites
    @player.ship.draw()
    arrow.draw() for arrow in @player.arrows
    @drawHUD()
    @pager.draw()

  gameOver: ->
    console.log 'Game over!'
    @player.ship.isDeleted = true

    @c.fillStyle = "#fff"
    @c.font = '30px Helvetica'
    @c.fillText 'Game Over!', @canvas.halfWidth - 80, @canvas.halfHeight - 80
    @c.font = '14px Courier New'
    @c.fillText "Alright, that's it! I'm sick of it!",
      @canvas.halfWidth - 135, @canvas.halfHeight - 60
    @c.fillText "Shut the fuck up, I've got a gun!",
      @canvas.halfWidth - 130, @canvas.halfHeight - 42

  notifyServer: ->
    @player.updateInputLog()
    entry = @player.latestInputLogEntry
    # return unless entry.inputs.length
    # console.log 'sending', entry.sequence, entry.ship.position, entry.inputs
    @player.socket.emit 'input', entry

  step: (time) ->
    @player.inputs = @client.getMappedInputs()
    @updateMouse()
    @notifyServer()
    super time # the best kind
    @draw()
    @player.inputs = []
