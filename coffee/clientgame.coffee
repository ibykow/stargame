global = global or window

if require?
  Eventable = require './eventable'
  Phyiscal = require './physical'
  View = require './view'
  Pane = require './pane'
  Button = require './button'
  Client = require './client'
  Game = require './game'
  Pager = require './pager'
  Ship = require './ship'
  Player = require './player'
  GasStation = require './gasstation'
  Market = require './market'

{abs, floor, max, min} = Math
rnd = Math.random
isarr = Array.isArray

pesoChar = Config.common.chars.peso

Ship::fire = -> @firing = true

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
  constructor: (@canvas, @params) ->
    return unless @canvas? and @params?
    @prevTime = +new Date

    @c = @canvas.getContext '2d'
    @starStates = @params.starStates
    @serverTick = @params.tick
    @params.tick = @tick = count: @serverTick.count

    @screenOffset = [0, 0]
    @visibleViews = []
    @mouseViews = [] # views under the mouse

    super @params

    @params.player.socket = @params.socket
    @player = Player.fromState @, @params.player
    @player.state = @params.player
    @player.ship.insertView()

    handler = @player.on 'refuel-error', (data) ->
      switch data.type
        when '404' then info = "Can't find the station."
        when 'distance' then info = "You're too far from the station."
        when 'nsf' then info = "You don't have any money for fuel."
        when 'full' then info = "You're already full on fuel."
        else return
      @page info

    handler.repeats = true

    @player.name = 'Guest'
    @lastVerifiedInputSequence = 0

    @generateStars()
    @pager = new Pager @
    @page = @pager.page.bind @pager
    @initializeContextMenu()

  interpolation:
    reset: ->
      @step = 0
      @rate = 1 / Config.server.updatesPerStep

  events:
    'new': [{
        timeout: 0
        repeats: true
        callback: (data, handler) ->
          return unless (type = data.type) and (v = @player.ship.view)

          switch type
            # Add an arrow to a new player's ship
            when 'InterpolatedShip' then v.arrowTo data.view

            # Add arrows to other play's ships when our ship (re)generates
            when 'Ship' then @each 'InterpolatedShip', (s) -> v.arrowTo s.view

      }, {
        deleted: true
        timeout: 0
        repeats: true
        callback: (data, handler) ->
          return unless data?.type is 'Bullet'
          console.log 'created new bullet at', data.position
    }]

  initializeContextMenu: ->
    @contextMenu = new Pane @,
      alpha: 0.5
      colors:
        text: '#FFF'
        background:
          current: '#00F'
          hover: '#00F'
          leave: '#00F'

    @contextMenu.resize()

    timer = new Timer @tick.count, 60 * 30, =>
      @page 'Move your mouse to the far right to open the menu ->'

    timer.repeats = true
    timer.callback()

    @contextMenu.on 'open', -> timer.delete()
    handler = @contextMenu.immediate 'mouse-leave', => @contextMenu.close()

    handler.repeats = true

    params =
      alpha: 0.25
      dimensions: [20, 0]

    sensor = @contextMenuSensor = new Pane @, params
    sensor.resize()
    sensor.open()
    handler = sensor.immediate 'mouse-enter', => @contextMenu.toggle()
    handler.repeats = true

  # quick and dirty
  testPager: ->
    @pager.page('Hello, World Number ' + i) for i in [1..20]
    console.log @pager.ring

  generateStars: -> Star.fromState @, state, true for state in @starStates

  resized: -> @emit 'resize'

  removeShip: (id) -> @lib['InterpolatedShip']?[id]?.delete()

  correctPrediction: ->
    # Make sure we have a state to work with
    return unless state = @player.state.ship

    # If there's a ship ID mismatch, regenerate from the server's state
    return @player.generateShip state, true unless @player.ship?.id is state.id

    inputLog = @player.logs['input']
    serverInputSequence = @player.state?.inputSequence

    return unless serverInputSequence > @lastVerifiedInputSequence

    @lastVerifiedInputSequence = serverInputSequence

    serverStep = @serverTick.count

    # Remove logged inputs prior to the server's input sequence
    # We won't be using those for anything
    inputLog.purge (entry) -> entry.sequence < serverInputSequence

    logEntry = inputLog.remove()

    # Move to the server state if we don't have any inputs to go on
    return @player.ship.setState state if not logEntry?

    {damaged, firing, fuel, health, position} = state

    @player.ship.firing = firing
    @player.ship.fuel = fuel
    @player.ship.health = health
    @player.ship.damaged = damaged

    # do the correction only if we're out of sync with the server
    clientPosition = logEntry.ship.position

    # console.log 'correct', position, 'vs', clientPosition
    return unless Util.vectorDeltaExists clientPosition, position

    console.log 'correcting ship state'

    # set the current ship state to the last known (good) server state
    @player.ship.setState state

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

  processBulletData: (data) ->
    # Add new bullets
    Bullet.fromState @, state, true for state in data.new

    # Remove dead bullets
    @lib['Bullet']?[id]?.delete() for id in data.dead

  processServerData: (data) ->
    # Store the most recent server tick data
    @serverTick = data.game.tick
    # Make it so we don't fall behind the server game tick
    @tick.count = @serverTick.count + 1 if @serverTick.count > @tick.count

    @processBulletData data.bullets

    # remove our ship from the pile
    index = data.players.findIndex (s) => s.id is @player.id
    @player.state = (data.players.splice index, 1)[0]

    InterpolatedShip.fromState @, state.ship, true for state in data.players

    @removeShip id for id in data.game.deadShipIDs

    @interpolation.reset()
    @correctPrediction()

  isMouseInBounds: (bounds) ->
    Util.isInSquareBounds [@client.mouse.x, @client.mouse.y], bounds

  moveMouse: ->
    @client.mouse.moved = false
    previousViews = @mouseViews
    @mouseViews = []
    # @contextMenu.toggle() if @client.mouse.x > @canvas.width - 30

    # Create new list of mouseViews
    for view in @visibleViews
      continue unless @isMouseInBounds view.getBounds()
      view.hovering = true
      @mouseViews.push view
      view.emit 'mouse-enter' unless ~previousViews.indexOf view

    # Remove items from the old list
    for view in previousViews when ~@mouseViews.indexOf(view) is 0
      view.hovering = false
      view.emit 'mouse-leave'

  updateMouse: ->
    m = @client.mouse

    # update mouseViews list
    @moveMouse() if m.moved

    # process click, press and release events
    view.emit 'mouse-click', m.buttons for view in @mouseViews if m.clicked
    view.emit 'mouse-press', m.buttons for view in @mouseViews if m.pressed
    view.emit 'mouse-release', m.buttons for view in @mouseViews if m.released

    # clear mouse related flags
    m.clicked = false
    m.pressed = false
    m.released = false

  update: ->
    unless @player.ship?
      return unless @player.state.ship
      @player.generateShip @player.state.ship, true

    @player.inputs = @client.getKeyboardInputs()
    super()
    star.view.update() for id, star of @lib['Star']
    bullet.view.update() for id, bullet of @lib['Bullet'] or {}

    ship.update() for id, ship of @lib['InterpolatedShip'] or {}

    @player.update()
    @contextMenuSensor.update()
    @contextMenu.update()

    @updateMouse()
    @interpolation.step++

    arrow.update() for id, arrow of @lib['Arrow'] or {}

  clearScreen: ->
    @c.globalAlpha = 1
    @c.fillStyle = Config.client.colors.background.default
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  draw: ->
    @clearScreen()
    view.draw() for view in @visibleViews
    @player.ship?.view.drawHUD 2, 2
    @pager.draw()

  gameOver: ->
    console.log 'Game over!'
    @player.ship.delete()

    @c.fillStyle = "#FFF"
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
    @deadBulletIDs = []
    @deadShipIDs = []
    @player.inputs = []
    @visibleViews = []
