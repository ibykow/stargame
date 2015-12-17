# Make Client exportable to support tests
client = null

(module ? {}).exports = class Client
  @INNER_WIDTH_OFFSET: 4
  @FRAME_MS: 16
  @URI: 'http://localhost:3000'
  @COLORS:
      BACKGROUND:
          DEFAULT: "#444"

  constructor: (@canvas) ->
    return unless @canvas

    @canvas.style.padding = 0
    @canvas.style.margin = 0
    @canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px'

    @eventHandlers.resize.call(@)
    @c = canvas.getContext('2d')
    @g = new Game()

    window.addEventListener(event, @eventHandlers[event]) for event of @eventHandlers

    @socket = io.connect(Client.URI)

    # Check this in JS
    @socket.on 'init', (data) =>
      @state = data.state
      @id = data.id
      console.log 'init', data.id, @
      @frame.run.call(@, 0)

    @socket.on 'state', (data) =>
      @state = data

    @socket.on 'newPlayer', (playerID) =>
      console.log 'player', playerID, 'is new'

    @socket.on 'playerLeft', (playerID) =>
      console.log 'player', playerID, 'has left'
      @state.players?.splice(playerID - 1, 1)

    @socket.on 'disconnect', =>
      console.log 'Game over!'
      @frame.stop()
      @socket.close()

  eventHandlers:
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

  clear: ->
    @c.globalAlpha = 1
    @c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT
    @c.fillRect 0, 0, @canvas.width, @canvas.height

  update: ->
    if @state
      @g.patch @state
      @state = null

    player.update() for player in @g.players

  drawPlayer: (p) ->
    return unless p and p.ship
    @c.fillStyle = p.ship.color
    @c.fillRect p.ship.position[0], p.ship.position[1], 10, 10

  draw: ->
    @clear()
    @drawPlayer p for p in @g.players

  frame:
    run: (timestamp) ->
      @update()
      @draw()

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
      id = window.setTimeout((-> callback(currTime + timeToCall)), timeToCall)
      lastTime = currTime + timeToCall
      id

  window.cancelAnimationFrame ?= (id) -> clearTimeout(id)
)()
