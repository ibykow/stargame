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
    url = Config.common.url
    uri = 'http://' + url.address + ':' + url.port
    @socket = io.connect uri

    # initialize event listeners
    @socket.on(event, cb.bind @) for event, cb of @events.socket
    window.addEventListener(event, cb.bind @) for event, cb of @events.window

    # resize the canvas for the first time
    @events.window.resize.call @

    # intialize the keymap
    @keymap = new Array 0xFF
    for key, action of Config.client.key.map
      code = Config.client.key.codes[key] or key.toUpperCase().charCodeAt 0
      @keymap[code] = action

    @keys = (false for [0..0xFF])
    @modifiers = 0 # Keyboard modifiers keys
    @mouse =
      buttons: 0
      x: 0
      y: 0

  resizedCallback: -> # overwrite this when a new game is created

  getKeyboardInputs: ->
    map: (@keymap[i] for i in [0...@keymap.length] when @keys[i] and @keymap[i])
    modifiers: @modifiers

  events:
    socket:
      disconnect: ->
        @frame.stop.bind(@)()
        @socket.close()

      error: (err) ->
        console.log "Error:", err

      join: (data) -> console.log 'Player ' + data.id + ' joined the game'

      leave: (id) ->
        @game.removeShip id
        console.log 'Player ' + id + ' has left the game'

      ship: (state) -> @game.player.generateShip state, true

      welcome: (data) ->
        return console.log 'Error (Welcome):', data unless data?.game?

        console.log 'Welcome:', data

        data.game.socket = @socket
        @game = new ClientGame @canvas, data.game
        @game.client = @
        @socket.emit 'join', @game.player.name
        @resizedCallback = @game.resized.bind @game
        @events.window.resize.call @ # Resize one more time

        # update the state event handler
        callback = @game.processServerData.bind @game
        @socket.on 'state', callback

        # process the new state
        callback data

        # start the game
        @frame.run.bind(@) Date.now()

    window:
      keydown: (e) ->
        bits = Config.common.modifiers.bits
        @keys[e.keyCode] = true
        @modifiers |= bits.alt if e.altKey
        @modifiers |= bits.ctrl if e.ctrlKey
        @modifiers |= bits.meta if e.metaKey
        @modifiers |= bits.shift if e.shiftKey

      keyup: (e) ->
        bits = Config.common.modifiers.bits
        @keys[e.keyCode] = false
        @modifiers ^= @modifiers & bits.alt if e.altKey
        @modifiers ^= @modifiers & bits.ctrl if e.ctrlKey
        @modifiers ^= @modifiers & bits.meta if e.metaKey
        @modifiers ^= @modifiers & bits.shift if e.shiftKey

      click: (e) -> @mouse.clicked = true

      mousedown: (e) ->
        @mouse.pressed = true
        @mouse.buttons |= e.button + 1

      mouseup: (e) ->
        @mouse.released = true
        @mouse.buttons ^= @mouse.buttons & (e.button + 1)

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
        @resizedCallback() # lets others get the message

  frame:
    request: null
    run: (timestamp) ->
      @frame.request = window.requestAnimationFrame @frame.run.bind @
      @game.step timestamp
    stop: ->
      @game.gameOver()
      window.cancelAnimationFrame @frame.request

# Load
window.onload = ->
  client = new Client document.querySelector 'canvas'

  # Request frame initialization
  lastTime = 0
  vendors = ['webkit', 'moz']

  for vendor in vendors
    break if window.requestAnimationFrame
    window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame']
    window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] or
      window[vendor + 'CancelRequestAnimationFrame']

  if not window.requestAnimationFrame
    window.requestAnimationFrame = (callback, element) ->
      ms = Config.common.msPerFram
      currTime = Date.now()
      timeToCall = Math.max 0, ms - (currTime - lastTime)
      lastTime = currTime + timeToCall
      window.setTimeout (-> callback lastTime), timeToCall

    window.cancelAnimationFrame ?= (id) -> clearTimeout(id)
