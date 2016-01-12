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

  processStats: ->
    @stats.dt.average = @stats.dt.average * 0.9 + @stats.dt.last * 0.1
    @stats.dt.min = min @stats.dt.min, @stats.dt.last
    @stats.dt.max = max @stats.dt.max, @stats.dt.last
    if @game.tick.count % (60 * 5) is 0
      console.log 'dt', @stats.dt.last.toFixed(4), @stats.dt.average.toFixed(4),
        @stats.dt.max.toFixed(4)

  unpause: ->
    console.log 'Unpausing'
    @frame.run.bind(@) +new Date

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
        (@immediate 'die', => @generateShip Config.common.ship).repeats = true

        # Introduce ourselves to the other players
        @socket.broadcast.emit 'join', { name: name, id: @id }
        @game.server.numPlayers++

        # start / unpause the game if it's the first player
        @game.server.unpause() if @game.server.numPlayers is 1

      disconnect: ->
        return unless @?
        console.log 'Player', @id, 'has left'

        # Tell the others that this player has left
        @game.server.io.emit 'leave', @ship.id

        # Destroy the player object associated with this socket
        @delete()

        @game.server.numPlayers--

        # Pause the game if it's empty
        @game.server.pause() if @game.server.numPlayers is 0

      error: (error) ->
        lg "ERROR: ", error
        lg "I say we just ignore this, keep going and see what happens. -" + @id

      # Handle player input
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
        @frame.request = setInterval (=> @frame.run.bind(@) +new Date), ms
        @started = true

      @stats.dt.last = process.hrtime()[1]
      @game.step timestamp
      @stats.dt.last = (process.hrtime()[1] - @stats.dt.last) / 1000000
      @processStats()

    stop: -> clearInterval(@frame.request)
