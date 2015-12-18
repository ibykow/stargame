client = null

# Make Client exportable to support tests
(module ? {}).exports = class Client
  @INNER_WIDTH_OFFSET: 4
  @FRAME_MS: 16
  @URI: 'http://192.168.0.101:3000'
  @COLORS:
    BACKGROUND:
      DEFAULT: "#000"

  constructor: (@canvas) ->
    return unless @canvas

    # initialize canvas
    @canvas.style.padding = 0
    @canvas.style.margin = 0
    @canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px'

    # connect to server
    @socket = io.connect(Client.URI)

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

  generateInput: ->
    for i in [0...@keymap.length] when @keys[i] and @keymap[i]
      @keymap[i]

  events:
    socket:
      welcome: (data) ->
        context = @canvas.getContext('2d')

        @game = new ClientGame(data, @canvas, context, data.player.id)

        @keymap[32] = 'brake'
        @keymap[37] = 'left'
        @keymap[38] = 'forward'
        @keymap[39] = 'right'
        @keymap[40] = 'reverse'

        @socket.emit 'join', @game.player.name
        @frame.run.bind(@) @game.tick.time

      join: (data) ->
        console.log 'player', data.id + ', ' + data.name, 'has joined'

      leave: (id) ->
        console.log 'player', id, 'has left'

      disconnect: ->
        console.log 'Game over!'
        @frame.stop.bind(@)()
        @socket.close()

      state: (data) ->
        @game.state = data unless @game.state.tick.count > data.tick.count

    window:
      keydown: (e) ->
        @keys[e.keyCode] = true

      keyup: (e) ->
        @keys[e.keyCode] = false

      mousemove: (e) ->
        @mouse.x = e.clientX - canvas.boundingRect.left
        @mouse.y = e.clientY - canvas.boundingRect.top

      mousedown: (e) ->
        @mouse.buttons[e.button] = true

      mouseup: (e) ->
        @mouse.buttons[e.button] = false

      click: (e) ->

      resize: (e) ->
        @canvas.width = window.innerWidth - Client.INNER_WIDTH_OFFSET
        @canvas.height = window.innerHeight - Client.INNER_WIDTH_OFFSET
        @canvas.halfWidth = @canvas.width >> 1
        @canvas.halfHeight = @canvas.height >> 1
        @canvas.boundingRect = @canvas.getBoundingClientRect()

  frame:
    run: (timestamp) ->
      input = @game.player.input = @generateInput()

      @game.step timestamp

      inputLogEntry =
        tick: @game.tick
        input: input

      @game.inputs.push inputLogEntry

      if input.length
        @socket.emit 'input', inputLogEntry

      @frame.request = window.requestAnimationFrame @frame.run.bind @

    stop: ->
      window.cancelAnimationFrame @frame.request

    request: null

window.onload = ->
  client = new Client(document.querySelector 'canvas')

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
      timeToCall = Math.max(0, client.FRAME_MS - (currTime - lastTime))
      lastTime = currTime + timeToCall
      window.setTimeout((-> callback(currTime + timeToCall)), timeToCall)

  window.cancelAnimationFrame ?= (id) -> clearTimeout(id)
)()
