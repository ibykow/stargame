Config = require './config'
Player = require './player'
Ship = require './ship'
Game = require './game'
ServerGame = require './servergame'

{max, min} = Math
lg = console.log.bind console

module.exports = class Server
  constructor: (@io) ->
    return unless @io
    # create a new game
    @stats =
      dt:
        last: 0
        average: 0
        min: 10
        max: 0

    @game = new ServerGame @, Config.server.game
    @frameInterval = Config.server.updatesPerStep * Config.common.msPerFrame
    console.log 'Server frame interval:', @frameInterval + 'ms'

    @numPlayers = 0

    # initialize io event handlers
    @io.on(event, cb.bind @) for event, cb of @events.io

  pause: ->
    console.log 'The game is empty. Pausing.'
    @frame.stop.bind(@)()

  unpause: ->
    console.log 'Unpausing'
    @frame.run.bind(@) Date.now()

  events:
    # @ is the server instance
    io:
      error: (err) -> console.log 'IO Error:', err
      connection: (socket) -> # a client connects
        # create a player object around the socket
        player = new Player @game,
          ship: Config.common.ship
          socket: socket

        # associate event handlers
        socket.on(event, cb.bind player) for event, cb of @events.socket

        @game.sendInitialState player
        @game.emit 'join', player.id

    # @ is the player instance
    socket:
      # join: officially join the game
      join: (name) ->
        console.log 'Player', @id, 'joined'

        @name = name
        @now 'die', => @generateShip Config.common.ship

        # Introduce ourselves to the other players
        @socket.broadcast.emit 'join', { name: name, id: @id }
        @game.server.numPlayers++

        # start / unpause the game if it's the first player
        @game.server.unpause() if @game.server.numPlayers is 1

      disconnect: (reason) ->
        return unless @?

        # Tell the others that this player has left
        @game.server.io.emit 'leave', @ship.id

        # Destroy the player object associated with this socket
        @delete 'due to socket ' + reason

        @game.server.numPlayers--

        # Pause the game if it's empty
        @game.server.pause() if @game.server.numPlayers is 0

      error: (error) ->
        lg "ERROR: ", error
        lg "I say we just ignore this, keep going and see what happens."

      input: (data) ->
        return unless data.sequence and @ship
        @gasStationIndex = data.gasStationIndex
        @inputSequence = data.sequence
        @inputs = data.inputs
        @update()

  frame:
    run: (timestamp) ->
      unless @started
        ms = @frameInterval - 3
        @frame.interval = setInterval (=> @frame.run.bind(@) Date.now()), ms
        @started = true

      @game.step timestamp

    stop: ->
      clearInterval @frame.interval
      @started = false
