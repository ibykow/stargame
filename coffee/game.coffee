(module ? {}).exports = class Game
  @isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v

  @randomInt: (min = 0, max = 99) ->
    return Math.floor(Math.random() * (max - min) + min)

  @padString: (s, n = 2, p = '0') ->
    return '' unless s and typeof s is 'string'
    len = n - s.length
    return s if len <= 0
    (p for [1..len]).join('') + s

  @randomColorString: (min = 0xff >> 1, max = 0xff) ->
    '#' + Game.padString(Game.randomInt(min, max).toString 16) +
      Game.padString(Game.randomInt(min, max).toString 16) +
      Game.padString(Game.randomInt(min, max).toString 16)

  constructor: (@width = 800, @height = 800) ->
    @players = []
    @objects = []

  randomPosition: ->
    [ Game.randomInt(0, @width), Game.randomInt(0, @height)]

  serialize: ->
    states = []
    for player in @players
      states.push player.serialize() unless not player
    { width: @width, height: @height, players: states }

  patch: (state) ->
    @width = state.width ? @width
    @height = state.height ? @height

    return unless state.players
    for playerState in state.players
      index = playerState.id - 1
      player = @players[index]
      if player then player.patch(playerState)
      else @players[index] = @playerFromState(playerState)

  playerFromState: (playerState) ->
    p = new Player(@, playerState.id, null, playerState.name)
    p.state = playerState
    p.ship = new Ship(p, playerState.ship)

  @GameObject: class GameObject
    constructor: (@game, @position = @game.randomPosition(),
      @theta = 0, @color = Game.randomColorString()) ->

  @MovableObject: class MovableObject extends Game.GameObject
    constructor: (@game, @position, @theta, @color, @velocity = [0, 0]) ->
      super(@game, @position, @theta, @color)

    accelerate: ->
      @velocity[0] -= @velocity[0] * @game.friction
      @velocity[1] -= @velocity[1] * @game.friction

    updateVelocity: ->
      @velocity[0] && @velocity[1]

    updatePosition: ->
      @position[0] = (@position[0] + @velocity[0] + @game.width) % @game.width
      @position[1] = (@position[1] - @velocity[1] + @game.height) % @game.height

    update: ->
      @accelerate()
      @updatePosition() if @updateVelocity()

  @Star: class Star extends MovableObject
    @MAX_SIZE: 30
    constructor: (@game) ->
      super(@game)
      @size = Math.floor(Math.random() * Star.MAX_SIZE)

  @Player: class Player
    constructor: (@game, @id, @socket, @name = 'Bob') ->
      return unless @game and @id
      @ship = new Ship @, {}
      @keys = (false for [1..0xFF])
    serialize: ->
        { id: @id, name: @name, ship: @ship?.serialize() }

    patch: (state) ->
      @color = state.color ? @color
      @ship.patch(state.ship) if state.ship

  @Ship: class Ship extends MovableObject
    constructor: (@player, state = {@position, @theta, @velocity, @color }) ->
      return unless @player and state
      super(@player.game, @position, @theta, @color)
    serialize: ->
      { position: @position, orientation: @orientation, velocity: @velocity,
      theta: @theta, color: @color }
    patch: (state) ->
      for key of state
        @[key] = state[key]
      @position = state.position
