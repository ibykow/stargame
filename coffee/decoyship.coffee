if require?
  Config = require './config'
  Timer = require './timer'
  Util = require './util'
  Projectile = require './projectile'
  Ship = require './Ship'
  ShipView = require './shipview'

{cos, floor, sin} = Math
rnd = Math.random

(module ? {}).exports = class DecoyShip extends Ship
  constructor: (@game, @params) ->
    return unless @game? and @params?.source
    {@offset, @source} = @params
    delete @params['id']
    @params.type = 'Ship' # Pretend to be a regular ship
    @holographic ?= true
    @offset ?= @getRandomOffset()
    super @game, @params

  initHandlers: ->
    # We move and die with the source
    @source.now 'delete', (id) =>
      new Timer floor(rnd() * 180), =>
        @game.deadShipIDs.push @id
        @explode 'because it was a decoy of ship ' + id

    move = @move.bind @
    @source.now 'move', move
    @source.now 'turn', move

  move: ->
    @position[0] = @source.position[0] + @offset[0]
    @position[1] = @source.position[1] + @offset[1]
    @rotation = @source.rotation

  getRandomOffset: (distance) ->
    distance ?= 10 + floor rnd() * 140
    theta = rnd() * Util.TWO_PI
    [cos(theta) * distance, sin(theta) * distance]

  setState: (state) ->
    super state
    @type = @constructor.name
