Config = require './config'
Player = require './player'
Game = require './game'
ServerGame = require './servergame'

[max, min] = [Math.max, Math.min]

mapSize = Config.common.mapSize

module.exports = class Server
  constructor: (@io) ->
    return unless @io
    # create a new game
    @game = new ServerGame(@, mapSize, mapSize, 4000, 0.99)
    @frameInterval = Config.server.updatesPerStep * Config.common.msPerFrame
    console.log 'Server frame interval:', @frameInterval + 'ms'

    # initialize io event handlers
    @io.on(event, cb.bind @) for event, cb of @events.io

  pause: ->
    console.log 'The game is empty. Pausing.'
    @frame.stop.bind(@)()

  unpause: ->
    console.log 'Unpausing'
    @frame.run.bind(@) +new Date

  events:
    # @ is the server instance
    io:
      connection: (socket) -> # a client connects
        # create a player object around the socket
        player = new Player @game, socket
        @game.players.push player
        @game.ships.push player.ship
        @nextPlayerID++

        # associate event handlers
        socket.on(event, cb.bind player) for event, cb of @events.socket

        @game.sendInitialState player
        console.log 'Player', player.id, 'has joined'

    # @ is the player instance
    socket:
      join: (name) -> # a connected client sends his/her name
        console.log 'Player', @id, 'is called', name

        # set the player's name
        @name = name

        # notify other players of the player's name and id
        @socket.broadcast.emit 'join', { name: name, id: @id }

        # start / unpause the game if it's the first player
        @game.server.unpause() if @game.players.length is 1

      disconnect: -> # a client has disconnected
        console.log 'Player', @id, 'has left'

        # notify other players that the player has left
        @game.server.io.emit 'leave', @id

        # destroy the player object associated with this socket
        @game.removePlayer(@)

        # if this was the last player, pause the game
        @game.server.pause() if @game.players.length is 0

      input: (data) -> # a client has generated input
        return unless data.sequence
        @inputSequence = data.sequence
        @inputs = data.inputs
        @game.gasStationID = data.gasStationID
        @update()

  frame:
    run: (timestamp) ->
      # console.log 'step'
      dt = +new Date
      @game.step timestamp
      dt = +new Date - dt
      ms = @frameInterval - dt

      if ms < 10
        ms = 10

      @frame.request = setTimeout (=> @frame.run.bind(@)(+new Date)), ms

    stop: ->
      clearTimeout(@frame.request)
