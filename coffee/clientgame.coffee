global = global or window

if require?
  Olib = require './olib'
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

Emitter::arrowTo = (view, color, alpha = 1, lineWidth = 1) ->
  new Arrow @game,
    a: @ # origin
    b: view # target
    color: color ? view.model.color
    alpha: alpha
    lineWidth: lineWidth

(module ? {}).exports = class ClientGame extends Game
  constructor: (@canvas, @params) ->
    return unless @canvas? and @params?
    @prevTime = Date.now()

    @c = @canvas.getContext '2d'
    @starStates = @params.starStates
    @serverTick = @params.tick
    @params.tick = count: @serverTick.count

    @screenOffset = [0, 0]
    @resetDeltas()

    @visibleViews = []
    @mouseViews = [] # views under the mouse

    @pager = new Pager @
    @page = @pager.page.bind @pager
    super @params
    @types = Config.client.types

    @minimap = new Minimap @

    @params.player.socket = @params.socket
    @player = Player.fromState @, @params.player
    @player.state = @params.player

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

    @generateStars @starStates
    @initContextMenu()

    @player.actions['zoomIn'] = @minimap.zoomIn.bind @minimap
    @player.actions['zoomOut'] = @minimap.zoomOut.bind @minimap

  interpolation:
    reset: ->
      @step = 0
      @rate = 1 / Config.server.updatesPerStep

  initHandlers: ->
    @now 'new', (emitter) -> emitter.insertView?()

    @on 'new', (model) =>
      return unless @player.ship and type = model?.type

      switch type
        when 'InterpolatedShip' then @minimap.track model
        when 'Ship'
          @updateScreenOffset()
          model.on 'move', (@updateScreenOffset.bind @)
          model.now 'delete', => @minimap.visible = false
          @minimap.visible = true if @minimap.count

        when 'Star' then model.now 'mouse-click', model.explode.bind model

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

  # Correct the player's ship state
  correctPrediction: (state) ->
    inputLog = @player.logs['input']
    serverInputSequence = state.inputSequence

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

    @player.ship.damaged = damaged
    @player.ship.firing = firing
    @player.ship.fuel = fuel
    @player.ship.health = health

    # do the correction only if we're out of sync with the server
    clientPosition = logEntry.ship.position

    return unless Util.vectorDeltaExists clientPosition, position
    delta = Util.toroidalDelta clientPosition, position, @toroidalLimit

    console.log 'Correcting ship position by ' + delta

    # Just jump to the correct position if the error is small
    return @player.position = position if (delta[0] < 5) and (delta[1] < 5)

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
    @player.ship?.view.drawHUD @hudX, 2
    @pager.draw()

  gameOver: ->
    console.log 'Game over!'
    @player.ship.delete "because it's game over for player", @player.id

    @c.fillStyle = "#FFF"
    @c.font = '30px Helvetica'
    @c.fillText 'Game Over!', @canvas.halfWidth - 80, @canvas.halfHeight - 80

  generateStars: (states) -> Star.fromState @, state for state in states

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

    timer = new Timer 60 * 30, =>
      @page 'Move your mouse to the far right to open the menu ->'

    timer.repeats = true
    timer.callback()

    @contextMenu.once 'open', -> timer.delete()
    @contextMenu.now 'mouse-leave', => @contextMenu.close()

    params = Config.client.contextMenu.sensor
    params.parent = @contextMenu

    @contextMenu.sensor = new Pane @, params
    @contextMenu.sensor.resize()
    @contextMenu.sensor.now 'mouse-enter', => @contextMenu.toggle()
    @contextMenu.sensor.open()
    @contextMenu.close()

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

    # Find items that are no longer under the mouse
    for view in previousViews when ~@mouseViews.indexOf(view) is 0
      view.hovering = false
      view.emit 'mouse-leave'

  notifyServer: ->
    @player.updateInputLog()
    entry = @player.latestInputLogEntry
    @player.socket.emit 'input', entry

  processProjectileData: (data) ->
    # Add new projectiles
    Projectile.fromState @, state for state in data.new

    # Remove dead projectiles
    @lib.get('Projectile', id)?.delete 'because it died' for id in data.dead

  processServerData: (data) ->
    # Store the most recent server tick data
    @serverTick = data.game.tick

    # Make it so we don't fall behind the server game tick
    @tick.count = @serverTick.count + 1 if @serverTick.count > @tick.count

    @processProjectileData data.projectiles

    ships = data.game.ships
    return unless ships.length

    # Remove our ship from the pile
    if @player.ship?
      index = ships.findIndex (s) => s.id is @player.ship.id
      @correctPrediction ships.splice(index, 1)[0]

    for state in ships
      state.type = 'InterpolatedShip'
      InterpolatedShip.fromState @, state

    @removeShip id for id in data.game.deadShipIDs

    @interpolation.reset()

  removeShip: (id) -> @lib.get('InterpolatedShip', id)?.explode()

  resize: ->
    @screenSize = max @client.canvas.width, @client.canvas.height
    @screenPartitionRadius = 1 + ceil @screenSize / @partitionSize
    @hudX = @client.canvas.width - 70
    @emit 'resize'

  testExplosion: -> Explosion.fromState @,
    position: @player.ship.position.slice()

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

    @stars = @player.ship.around @screenPartitionRadius, 'Star'
    star.view.update() for star in @stars

    @player.update()
    @interpolation.step++
    @contextMenu.sensor.update()
    @contextMenu.update()
    @minimap.update()

    # Call this last because mouseUpdate needs visibleViews to be populated
    @updateMouse()

  step: (time) ->
    super time # the best kind
    @notifyServer()
    @draw()
    @deadShipIDs = []
    @player.inputs = []
