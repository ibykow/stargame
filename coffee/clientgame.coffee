global = global or window

if require?
  Emitter = require './emitter'
  Phyiscal = require './physical'
  View = require './view'
  Minimap = require './minimap'
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

Emitter::arrowTo = (view, color, alpha = 1, lineWidth = 1) ->
  new Arrow @game,
    a: @ # origin
    b: view # target
    color: color ? view.model.color
    alpha: alpha
    lineWidth: lineWidth

Ship::fire = -> @firing = true

(module ? {}).exports = class ClientGame extends Game
  constructor: (@canvas, @params) ->
    return unless @canvas? and @params?
    @prevTime = +new Date

    @c = @canvas.getContext '2d'
    @starStates = @params.starStates
    @serverTick = @params.tick
    @params.tick = count: @serverTick.count

    @screenOffset = [0, 0]
    @resetDeltas()

    @visibleViews = []
    @mouseViews = [] # views under the mouse
    @proximals = [] # All emitters around the player's ship

    @pager = new Pager @
    @page = @pager.page.bind @pager

    super @params
    @types = Config.client.types

    @params.player.socket = @params.socket
    @player = Player.fromState @, @params.player
    @player.state = @params.player
    @player.ship.insertView()

    @player.on 'refuel-error', (data) ->
      switch data.type
        when '404' then info = "Can't find the station."
        when 'distance' then info = "You're too far from the station."
        when 'nsf' then info = "You don't have money for fuel."
        when 'full' then info = "Your fuel is already full."
        else return
      @page info

    @player.name = 'Guest'
    @lastVerifiedInputSequence = 0

    @generateStars()
    @initContextMenu()
    @minimap = new Minimap @
    @contextMenu.on 'open', => @minimap.resize()
    @contextMenu.on 'close', => @minimap.resize()
    @contextMenu.close()

  interpolation:
    reset: ->
      @step = 0
      @rate = 1 / Config.server.updatesPerStep

  events:
    'new': [{
        timeout: 0
        repeats: true
        callback: (data, handler) ->
          return unless (type = data.type) and (myship = @player.ship)
          switch type
            # Add an arrow to a new player's ship
            when 'InterpolatedShip' then myship.view.arrowTo data.view
            when 'Explosion' then data.insertView()
            # Add arrows to other play's ships when our ship (re)generates
            when 'Ship'
              (myship.on 'move', @updateScreenOffset.bind @).callback()
              @each 'InterpolatedShip', (ship) -> myship.view.arrowTo ship.view
            when 'Star' then data.now 'mouse-click', -> data.explode()

      }, {
        deleted: true
        timeout: 0
        repeats: true
        callback: (data, handler) ->
          return unless data?.type is 'Projectile'
          console.log 'created new projectile at', data.position
    }]

  resetDeltas: ->
    @c.setTransform 1, 0, 0, 1, 0, 0
    @deltas =
      offset: [0, 0]
      rotation: 0

  clearScreen: ->
    @resetDeltas()
    @c.globalAlpha = 1
    @c.fillStyle = Config.client.colors.background.default
    @c.fillRect 0, 0, @canvas.width, @canvas.height

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

  draw: ->
    @clearScreen()

    view.draw() for view in @visibleViews
    @player.ship?.view.drawHUD 2, 2
    @pager.draw()

  gameOver: ->
    console.log 'Game over!'
    @player.ship.delete "because it's game over for player", @player.id

    @c.fillStyle = "#FFF"
    @c.font = '30px Helvetica'
    @c.fillText 'Game Over!', @canvas.halfWidth - 80, @canvas.halfHeight - 80
    @c.font = '14px Courier New'
    @c.fillText "Alright, that's it! I'm sick of it!",
      @canvas.halfWidth - 135, @canvas.halfHeight - 60
    @c.fillText "Shut the fuck up, I've got a gun!",
      @canvas.halfWidth - 130, @canvas.halfHeight - 42

  generateStars: -> Star.fromState @, state, true for state in @starStates

  initContextMenu: ->
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

    @contextMenu.once 'open', -> timer.delete()
    @contextMenu.now 'mouse-leave', => @contextMenu.close()

    params = Config.client.contextMenu.sensor
    params.parent = @contextMenu

    sensor = new Pane @, params
    sensor.resize()
    sensor.now 'mouse-enter', => @contextMenu.toggle()
    sensor.open()

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

  notifyServer: ->
    @player.updateInputLog()
    entry = @player.latestInputLogEntry
    @player.socket.emit 'input', entry

  processProjectileData: (data) ->
    # Add new projectiles
    Projectile.fromState @, state, true for state in data.new

    # Remove dead projectiles
    reason = 'because it died'
    @lib['Projectile']?[id]?.delete reason for id in data.dead

  processServerData: (data) ->
    # Store the most recent server tick data
    @serverTick = data.game.tick
    # Make it so we don't fall behind the server game tick
    @tick.count = @serverTick.count + 1 if @serverTick.count > @tick.count

    @processProjectileData data.projectiles

    # remove our ship from the pile
    index = data.players.findIndex (s) => s.id is @player.id
    @player.state = (data.players.splice index, 1)[0]

    InterpolatedShip.fromState @, state.ship, true for state in data.players

    @removeShip id for id in data.game.deadShipIDs

    @interpolation.reset()
    @correctPrediction()

  removeShip: (id) -> @lib['InterpolatedShip']?[id]?.explode()

  resized: ->
    screenSize = max @client.canvas.halfWidth, @client.canvas.halfHeight
    @screenPartitionRadius = (floor screenSize / @partitionSize) + 2
    @emit 'resize'

  testExplosion: -> Explosion.fromState @,
    position: @player.ship.position.slice(), true

  testPager: -> @pager.page('Hello, World Number ' + i) for i in [1..20]

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

  updateScreenOffset: ->
    x = @player.ship.position[0] - @canvas.halfWidth
    y = @player.ship.position[1] - @canvas.halfHeight
    @screenOffset = [x, y]

  update: ->
    # No ship, no update
    unless @player.ship?
      return unless @player.state.ship
      @player.generateShip @player.state.ship, true

    @visibleViews = []
    @player.inputs = @client.getKeyboardInputs()
    super()

    @proximals = @player.ship.around @screenPartitionRadius

    # for model in @proximals
    #   model.view.update() if ~@types.proximal.indexOf model.type
    @player.update()
    @interpolation.step++

    # Call this last because mouseUpdate needs visibleViews to be populated
    @updateMouse()

  step: (time) ->
    super time # the best kind
    @notifyServer()
    @draw()
    @deadProjectileIDs = []
    @deadShipIDs = []
    @player.inputs = []
