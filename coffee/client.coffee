if require?
  Config = require './config'

client = null

# Make Client exportable to support tests
(module ? {}).exports = class Client
  constructor: (@canvas) ->
    return unless @canvas

    # initialize canvas
    @canvas.style.padding = 0
    @canvas.style.margin = 0
    # @canvas.style.left = 0 + 'px'

    # connect to server
    @socket = io.connect(Config.common.uri)

    # initialize event listeners
    @socket.on(event, cb.bind(@)) for event, cb of @events.socket
    window.addEventListener(event, cb.bind(@)) for event, cb of @events.window

    # resize the canvas for the first time
    @events.window.resize.call @

    @keys = (false for [0..0xFF])
    @mouse =
      x: 0
      y: 0
      buttons: [false, false, false]

  keymap: new Array 0x100

  getMappedInputs: ->
    for i in [0...@keymap.length] when @keys[i] and @keymap[i]
      @keymap[i]

  events:
    socket:
      error: (err) ->
        console.log "Error:", err

      welcome: (data) ->
        context = @canvas.getContext('2d')

        @game = new ClientGame(data, @canvas, context, @socket)
        @game.client = @

        @keymap[Config.client.keyCodes.up] = 'forward'
        @keymap[Config.client.keyCodes.down] = 'reverse'
        @keymap[Config.client.keyCodes.left] = 'left'
        @keymap[Config.client.keyCodes.right] = 'right'
        @keymap[Config.client.keyCodes.space] = 'brake'
        @keymap[Config.client.keyCodes.f] = 'fire'

        @socket.emit 'join', @game.player.name
        @game.player.ship.setState(data.ship)
        @game.player.ship.updateView = @game.player.ship.updateViewMaster

      join: (data) ->
        console.log 'player', data.id + ', ' + data.name, 'has joined'

      leave: (id) ->
        @game.removeShip(id)
        console.log 'player', id, 'has left'

      disconnect: ->
        console.log 'Game over!'
        @frame.stop.bind(@)()
        @socket.close()

      state: (data) ->
        # set the first state
        return unless data.ships
        console.log 'received', data

        # update the state event handler
        callback = @game.processServerData.bind @game
        @socket.removeAllListeners('state')
        @socket.on('state', callback)

        # set the tick, then set and process the new state
        # @game.tick = data.tick
        callback data

        # start the game
        @frame.run.bind(@) @game.tick.time

    window:
      keydown: (e) -> @keys[e.keyCode] = true
      keyup: (e) -> @keys[e.keyCode] = false
      click: (e) -> @mouse.clicked = true
      mousedown: (e) ->
        @mouse.pressed = true
        @mouse.buttons[e.button] = true
      mouseup: (e) ->
        @mouse.released = true
        @mouse.buttons[e.button] = false
      mousemove: (e) ->
        @mouse.moved = true
        @mouse.x = e.clientX - canvas.boundingRect.left
        @mouse.y = e.clientY - canvas.boundingRect.top
      resize: (e) ->
        @canvas.width = window.innerWidth - Config.client.innerWidthOffset
        @canvas.height = window.innerHeight - Config.client.innerHeightOffset
        @canvas.halfWidth = @canvas.width >> 1
        @canvas.halfHeight = @canvas.height >> 1
        @canvas.boundingRect = @canvas.getBoundingClientRect()

  frame:
    run: (timestamp) ->
      @frame.request = window.requestAnimationFrame @frame.run.bind @
      @game.step timestamp

    stop: ->
      @game.gameOver()
      window.cancelAnimationFrame @frame.request

    request: null

window.onload = ->
  client = new Client(document.querySelector 'canvas')

# Frame request code
(->
  lastTime = 0
  vendors = ['webkit', 'moz']

  for vendor in vendors
    break if window.requestAnimationFrame
    window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame']
    window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] ||
      window[vendor + 'CancelRequestAnimationFrame']

  if not window.requestAnimationFrame
    window.requestAnimationFrame = (callback, element) ->
      currTime = +new Date
      timeToCall = Math.max(0, Config.common.msPerFrame - (currTime - lastTime))
      lastTime = currTime + timeToCall
      window.setTimeout((-> callback(lastTime)), timeToCall)

  window.cancelAnimationFrame ?= (id) -> clearTimeout(id)
)()
