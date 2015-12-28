log = console.log
Player = require './player'
Game = require './game'
ServerGame = require './servergame'

module.exports = class Server
  @FRAMES_PER_STEP: 5
  @MAP_SIZE: (1 << 15) + 1
  @startPosition: null
  constructor: (@io) ->
    return unless @io
    # create a new game
    @game = new ServerGame(@, Server.MAP_SIZE, Server.MAP_SIZE, 4000, 0.99)
    @frameInterval = Server.FRAMES_PER_STEP * Game.FRAME_MS
    @nextPlayerID = 0
    console.log 'Server frame interval:', @frameInterval + 'ms'

    # initialize io event handlers
    @io.on(event, cb.bind(@)) for event, cb of @events.io

  pause: ->
    log 'The game is empty. Pausing.'
    @frame.stop.bind(@)()

  unpause: ->
    log 'unpausing'
    @frame.run.bind(@) +new Date

  events:
    # @ is the server instance
    io:
      connection: (socket) -> # a client connects
        # create a player object around the socket
        player = new Player @game, @nextPlayerID, socket
        @game.players.push player
        @nextPlayerID++

        # associate event handler
        socket.on(event, cb.bind(player)) for event, cb of @events.socket

        # send the id and game information back to the client
        socket.emit('welcome',
          game:
            width: @game.width
            height: @game.height
            frictionRate: @game.frictionRate
            tick: @game.tick
            starStates: @game.starStates
          id: player.id,
          ship: player.ship.getState())

        log 'Player', player.id, 'has joined'

    # @ is the player instance
    socket:
      join: (name) -> # a connected client sends his/her name
        log 'Player', @id, 'is called', name

        # set the player's name
        @name = name

        # notify other players of the player's name and id
        @socket.broadcast.emit 'join', { name: name, id: @id }

        # start / unpause the game if it's the first player
        @game.server.unpause() if @game.players.length is 1

      disconnect: -> # a client has disconnected
        log 'Player', @id, 'has left'

        # notify other players that the player has left
        @game.server.io.emit 'leave', @id

        # destroy the player object associated with this socket
        @game.removePlayer(@)

        # if this was the last player, pause the game
        @game.server.pause() if not @game.players.length

      input: (data) -> # a client has generated input
        return unless data.sequence
        @inputs = data.inputs
        @clientState = data.ship
        @inputSequence = data.sequence
        @update()

  frame:
    run: (timestamp) ->
      dt = +new Date
      @game.step timestamp
      dt = +new Date - dt
      ms = @frameInterval - dt

      if ms < 10
        ms = 10

      @frame.request = setTimeout((=> @frame.run.bind(@)(+new Date)), ms)

    stop: ->
      clearTimeout(@frame.request)
