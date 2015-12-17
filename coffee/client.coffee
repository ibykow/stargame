client = null

# Make Client exportable to support tests
(module ? {}).exports = class Client
  @INNER_WIDTH_OFFSET: 4
  @FRAME_MS: 16
  @URI: 'http://192.168.0.101:3000'
  @COLORS:
    BACKGROUND:
      DEFAULT: "#444"

  constructor: (@canvas) ->
    return unless @canvas

    # initialize canvas
    @canvas.style.padding = 0
    @canvas.style.margin = 0
    @canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px'
    @events.window.resize.call @

    # connect to server
    @socket = io.connect(Client.URI)

    # initialize socket events
    @socket.on(event, cb.bind(@)) for event, cb of @events.socket

  events:
    socket:
      welcome: (data) ->
        context = @canvas.getContext('2d')

        @game = new ClientGame(data, @canvas, context, data.player.id)
        @socket.emit 'join', @game.player.name
        @frame.run.bind(@) @game.tick.time

        # Listen for window events
        addListener = window.addEventListener
        addListener(event, cb.bind(@)) for event, cb of @events.window


      join: (data) ->
        console.log 'player', data.id + ', ' + data.name, 'has joined'

      leave: (id) ->
        console.log 'player', id, 'has left'

      disconnect: ->
        console.log 'Game over!'
        @frame.stop.bind(@)()
        @socket.close()

      state: (data) ->
        @state = data

    window:
      keydown: (e) ->

      keyup: (e) ->

      mousemove: (e) ->

      mousedown: (e) ->

      mouseup: (e) ->

      click: (e) ->

      resize: (e) ->
        @canvas.width = window.innerWidth - Client.INNER_WIDTH_OFFSET

        @canvas.height = window.innerHeight -
          Client.INNER_WIDTH_OFFSET
        @canvas.halfWidth = @canvas.width >> 1
        @canvas.halfHeight = @canvas.height >> 1

  frame:
    run: (timestamp) ->
      @game.step timestamp
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
