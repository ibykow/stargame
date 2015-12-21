log = console.log
Player = require './player'
Game = require './servergame'

module.exports = class Server
  @FRAME_INTERVAL: 80
  @startPosition: null
  constructor: (@io) ->
    return unless @io

    # create a new game
    @game = new Game(@, (1 << 14) + 1, (1 << 14) + 1, 4000)

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
        player = null
        if Server.startPosition
          player = @game.newPlayer(socket, [
            Server.startPosition[0],
            Server.startPosition[1],
            0])
        else
          player = @game.newPlayer(socket)

        Server.startPosition ?= player.ship.position
        console.log 'position', Server.startPosition
        player.inputs = []

        # associate event handler
        socket.on(event, cb.bind(player)) for event, cb of @events.socket

        # send the id and game information back to the client
        socket.emit('welcome',
          game:
            width: @game.width
            height: @game.height
            frictionRate: @game.frictionRate
            tick: @game.tick
            initStates: @game.initStates
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
        # data =
          # pressed: [pressed, key, ids]
          # released: [released, key, ids]
          # tick:
            # count: clientCount
            # time: clientTime

        # push to local player object for handling in frame loop
        # discard if tick count is lower than last server sent tick count

        @inputs.push(data)
        # unless @game.server.ticks.sent and
        # data.tick.count < @game.server.ticks.sent.count

  frame:
    run: (timestamp) ->
      @game.step timestamp
      ms = Server.FRAME_INTERVAL
      @frame.request = setTimeout((=> @frame.run.bind(@) (+new Date)), ms)
    stop: ->
      clearTimeout(@frame.request)
