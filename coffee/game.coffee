root = exports ? this

root.Game = class Game
  @randomColorString: (range = 0xFFFFFF >> 2, base = range * 3) ->
    "#" + (Math.floor(Math.random() * range) + base).toString(16)

  @isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v;

  constructor: (@width = 800, @height = 800) ->
    @players = []
    @objects = []

  randomPosition: ->
    [ Math.floor(Math.random() * this.width),
      Math.floor(Math.random() * this.height) ]

  serialize: ->
    states = []
    for player in @players
      states.push player.serialize() unless not player
    { w: @width, h: @height, states: states }

  patch: (state) ->
    @width = state.w ? @width
    @height = state.h ? @height
    for playerState in state.p
      index = playerState.id - 1
      player = @players[index]
      if player then player.patch(playerState)
      else @players[index] = @playerFromState(playerState)

  playerFromState: (playerState) ->
    p = new Player(@, playerState.id, null, playerState.name)
    p.state = playerState
    p.ship = new Ship(p, playerState.ship)

  @GameObject: class GameObject
    constructor: (@game, @position = Game.randomPosition(),
      @theta = 0, @color = randomColorString()) ->

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
      @keys = (false for [1..0xFF])
    serialize: ->
        { id: @id, name: @name, ship: @ship?.serialize() }

    patch: (state) ->
      @color = state.color ? @color
      @ship.patch(state.ship) if state.ship

  @Ship: class Ship extends MovableObject
    constructor: (@player, {@position, @theta, @velocity, @color }) ->
      return unless @player
      super(@player.game, @position, @theta, @color)
    serialize: ->
      { position: @position, orientation: @orientation, velocity: @velocity
        theta: @theata, color: @color }
    patch: (state) ->
      for key of state
        @[key] = state[key]
      @position = state.position
