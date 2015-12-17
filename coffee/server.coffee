Player = require './player'
Game = require './servergame'
log = console.log

module.exports = class Server
  constructor: (@io) ->
    return unless @io

    # create a new game
    @game = new Game(@, 1024, 600, 10)

    # initialize io event handlers
    @io.on(event, cb.bind(@)) for event, cb of @events.io

  events:
    # @ is the server instance
    io:
      connection: (socket) -> # a client connects
        # create a player object around the socket
        player = @game.newPlayer(socket)

        # associate event handler
        socket.on(event, cb.bind(player)) for event, cb of @events.socket

        # send the id and game information back to the client
        socket.emit('welcome', {
          game:
            width: @game.width
            height: @game.height
            frictionRate: @game.frictionRate
            tick: @game.tick
            states: @game.states
          player:
            id: player.id
        })

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

      disconnect: -> # a client has disconnected
        log 'Player', @id, 'has left'

        # notify other players that the player has left
        io.emit 'leave', @id

        # destroy the player object associated with this socket
        @game.removePlayer(@)

        # if this was the last player, pause the game
        if not @game.players.length
          log 'The game is empty'

      input: (data) -> # a client has generated input
        # data =
          # pressed: [pressed, key, ids]
          # released: [released, key, ids]
          # tick:
            # count: clientCount
            # time: clientTime

        # push to local player object for handling in frame loop
        # discard if tick count is lower than last server sent tick count
        @inputs.push data unless @game.server.ticks.sent and
          data.tick.count < @game.server.ticks.sent.count
