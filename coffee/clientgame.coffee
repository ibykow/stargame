global = global or window

if require?
  Eventable = require './eventable'
  Sprite = require './sprite'
  Pane = require './pane'
  ButtonPane = require './buttonpane'
  GasStation = require './gasstation'
  Ship = require './ship'
  Game = require './game'
  Player = require './player'
  Client = require './client'
  Pager = require './pager'

{abs, floor, max, min} = Math
rnd = Math.random
isarr = Array.isArray

pesoChar = Config.common.chars.peso

Player::die = -> @ship.isDeleted = true
Sprite.updatePosition = ->
Sprite.updateVelocity = ->

(module ? {}).exports = class ClientGame extends Game
  @brakeStrings: [
    'BRAKE!',
    'Oh, dear God please stop!',
    'Oh lord, Pretus, Lord almighty!',
    'Stop now please. Stop now please. Stop now please.'
    'STOP!!!'
    'For the love of Pretus, stop already!'
    "We're all going to die!"
  ]
  constructor: (@canvas, socket, params) ->
    return unless params
    super params.game.width, params.game.height, params.game.frictionRate

    @c = @canvas.getContext '2d'
    @starStates = params.game.starStates
    @serverTick = params.game.tick
    @tick.count = @serverTick.count

    @visibleSprites = []
    @mouseSprites = [] # sprites under the mouse

    @player = new Player @, socket
    @player.id = params.id
    @player.name = 'Guest'
    @lastVerifiedInputSequence = 0
    @collisionSpriteLists.myShip = [@player.ship]
    @collisionSpriteLists.stars = @stars = @generateStars()
    @initializeEventHandlers()
    @pager = new Pager @
    @page = @pager.page.bind @pager
    @initializeContextMenu()

  interpolation:
    reset: ->
      @step = 0
      @rate = 1 / Config.server.updatesPerStep

  events:
    # accelerate: [ {
    #   callback: (data) ->
    #     @page "Woohoo! You're flying now!" if data.direction is 'forward'
    #   target: ['player', 'ship']
    #   timeout: 0
    #   repeats: false }
    # { callback: (data) ->
    #     if data.direction is 'brake'
    #       phrases = ClientGame.brakeStrings
    #       @page phrases[floor rnd() * phrases.length]
    #   target: ['player', 'ship']
    #   timeout: 0
    #   repeats: false }
    # ]

    # turn: [
    #   target: ['player', 'ship']
    #   timeout: 0
    #   repeats: false
    #   callback: (data) -> @page 'Woohoo! Your very first turn was to the ' +
    #     data.direction + ' by ' + abs(data.amount) + ' radians!'
    # ]

    refuel: [
      target: ['player']
      timeout: 0
      repeats: true
      callback: (data) ->
        station = @gasStations[data.index]
        info =
        @page 'You bought ' + data.delta.toFixed(2) + 'L of fuel for ' +
          pesoChar + data.price.toFixed(2) + ' at ' + pesoChar +
          station.fuelPrice.toFixed(2) + '/L'
    ]

    'refuel-error': [
      target: ['player']
      timeout: 0
      repeats: true
      callback: (data) ->
        switch data.type
          when '404' then info = "Can't find the station."
          when 'distance' then info = "You're too far from the station."
          when 'nsf' then info = "You don't have any money for fuel."
          when 'full' then info = "You're already full on fuel."
        @page info
    ]

  resized: -> @emit 'resize'

  initializeContextMenu: ->
    resizeCB = ->
      {width, height, halfHeight} = @game.canvas
      @view = [width - @width, 0, 0]
      @height = height
      @halfHeight = halfHeight
      @updateView()

    toggleCB = ->
      if @text is 'On'
        b.params.font.offset[0] = 14
        @text = 'Off'
      else
        b.params.font.offset[0] = 18
        @text = 'On'

    @contextMenu = new Pane @, [0, 0, 0], 360, 0, "#00f", false, 0.6, resizeCB
    b = new ButtonPane @contextMenu, 'testBtn', 'On', [100, 20], toggleCB
    b.params.font.offset[0] = 18

    @contextMenu.resize()

    callback = => @page 'Move your mouse to the right side of the screen ->'
    timer = new Timer @tick.count, 60 * 10, callback, @repeats = true
    @contextMenu.on 'open', -> timer.delete()
    callback()

  initializeEventHandlers: ->
    for name, handlers of @events
      target = @
      for info in handlers
        for child in info.target
          target = target[child]
          break if not target
        continue if not target
        target.on name, info.callback.bind(@), info.timeout, info.repeats

  # quick and dirty
  testPager: ->
    @pager.page('Hello, World Number ' + i) for i in [1..20]
    console.log @pager.buffer

  generateStars: ->
    for state in @starStates
      s = new Sprite @, state.position, state.width, state.height, state.color
      global[type].fromState s, cstate for type, cstate of state.children
      s # collect the stars together to return them

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

    serverStep = @serverTick.count

    # Remove logged inputs prior to the server's input sequence
    # We won't be using those for anything
    inputLog.purge (entry) -> entry.sequence < serverInputSequence

    logEntry = inputLog.remove()

    # Move to the server state if we don't have any inputs to go on
    return @player.ship.setState serverState if not logEntry?

    # do the correction only if we're out of sync with the server
    clientPosition = logEntry.ship.position
    serverPosition = serverState.position

    if serverState.health < logEntry.ship.health
      @player.ship.health = serverState.health

    if serverState.fuel < logEntry.ship.fuel
      @player.ship.fuel = serverState.fuel

    # console.log 'correct', serverPosition, 'vs', clientPosition
    return unless Util.vectorDeltaExists clientPosition, serverPosition

    # console.log 'correcting ship state'
    # console.log logEntry.sequence, logEntry.gameStep, clientPosition
    # console.log serverInputSequence, serverStep, serverPosition
    # console.log Util.toroidalDelta clientPosition, serverPosition,
    #   @toroidalLimit

    # set the current ship state to the last known (good) server state
    @player.ship.setState serverState

    # store the current entries
    entries = inputLog.toArray().slice()

    # dump the input log so it can be rebuilt
    inputLog.reset()

    # rewind and replay
    count = @tick.count
    @tick.count = logEntry.gameStep
    for entry in entries
      console.log 'replaying',
        entry.sequence, entry.gameStep, entry.ship.position

      @player.inputSequence = entry.sequence
      @player.inputs = entry.inputs
      @player.update()
      @player.updateInputLog()
      @tick.count++
    # @tick.count = count

  processBulletData: (data) ->
    # Remove dead bullets
    @bullets = @bullets.filter (b) ->
      (data.deadBulletIDs.indexOf(b.id) is -1) or
      (b.life > 0)

    # Add new bullets
    # TODO: Replace our bullet ids with server bullet ids
    for bullet in data.bullets when not (bullet.gun.id is @player.ship.id)
      @bullets.push Bullet.fromState @, bullet

  processServerData: (data) ->
    [inserted, i, j, stateLog] = [false, 0, 0, @player.logs['state']]

    # Store the most recent server tick data
    @serverTick = data.game.tick

    # Make it so we don't fall behind the server game tick
    if @serverTick.count > @tick.count
      # console.log 'Falling behind server by ' +
      #   (@serverTick.count - @tick.count)
      @tick.count = @serverTick.count + 1

    @processBulletData data

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
        @player.arrowTo ship

    # if a new player has entered, sort our list of ships by id
    (@ships.sort (a, b) -> a.id - b.id) if inserted

    # remove old states from the log
    # stateLog.purge (entry) -> entry.sequence < @serverTick.count
    @interpolation.reset()

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
    @client.mouse.moved = false

    # process click, press and release events
    if @client.mouse.clicked
      for sprite in @mouseSprites when sprite.mouse.click?
        sprite.mouse.click.bind(sprite) @client.mouse.buttons

    if @client.mouse.pressed
      for sprite in @mouseSprites when sprite.mouse.press?
        sprite.mouse.press.bind(sprite) @client.mouse.buttons

    if @client.mouse.released
      for sprite in @mouseSprites when sprite.mouse.release?
        sprite.mouse.release.bind(sprite) @client.mouse.buttons

    # clear mouse related flags
    @client.mouse.clicked = false
    @client.mouse.pressed = false
    @client.mouse.released = false

    @contextMenu.open() if @client.mouse.x > @canvas.width - 30

  update: ->
    @player.inputs = @client.getKeyboardInputs()
    super()
    star.update() for star in @stars
    ship.update() for ship in @ships
    @contextMenu.update() if @contextMenu.visible
    @updateMouse()
    @interpolation.step++
    @correctPrediction()
    @player.update()
    @player.updateArrows()

  clearScreen: ->
    @c.globalAlpha = 1
    @c.fillStyle = Config.client.colors.background.default
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  drawHUD: ->
    @player.ship.drawHUD 2, 2
    @c.fillStyle = "#fff"
    @c.font = "14px Courier New"
    @c.fillText pesoChar + @player.cash.toFixed(2), 0, 52

    @c.fillText @player.ship.position[0].toFixed(0), 80, 10
    @c.fillText @player.ship.position[1].toFixed(0), 140, 10
    @c.fillText @player.ship.position[2].toFixed(2), 200, 10

    @c.fillText @player.ship.velocity[0].toFixed(0), 80, 22
    @c.fillText @player.ship.velocity[1].toFixed(0), 140, 22
    @c.fillText @client.mouse.x.toFixed(0), 80, 34
    @c.fillText @client.mouse.y.toFixed(0), 140, 34

  draw: ->
    @clearScreen()
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
    @player.socket.emit 'input', entry

  step: (time) ->
    super time # the best kind
    @notifyServer()
    @draw()
    @player.inputs = []
    @visibleSprites = []
