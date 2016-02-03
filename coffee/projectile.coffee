if require?
  Config = require './config'
  Util = require './util'
  Physical = require './physical'

{ceil, cos, sin} = Math
{damage, life, speed} = Config.common.projectile

(module ? {}).exports = class Projectile extends Physical
  constructor: (@game, @params) ->
    return unless @game?
    id = @params?.shipID
    @ship = @game.lib['Ship']?[id] or @game.lib['InterpolatedShip']?[id]

    return console.log "WARNING! No ship means no projectile." unless @ship?

    {@damage, @life, @speed} = @params

    @damage ?= damage
    @life ?= life
    @speed ?= speed

    vx = @ship.velocity[0]
    vy = @ship.velocity[1]
    xdir = cos @ship.rotation
    ydir = sin @ship.rotation

    @params.color = @params.color ? '#FFD'
    @params.position =
      [ @ship.position[0] + xdir * (@ship.width + 2),
        @ship.position[1] + ydir * (@ship.height + 2),
        @ship.rotation ]
    @params.velocity = [xdir * @speed, ydir * @speed]
    @params.width = @params.height = 2

    super @game, @params

  delete: ->
    @game.deadProjectileIDs.push @id
    @life = 0
    super arguments[0]

  initHandlers: ->
    super()
    @now 'hit', (model) => @life -= model.damage
    @now 'move', (data, handler) =>
      return if @deleted
      models = @around 1
      for model in models when not (model.id is @id) and @intersects model
        handler.repeats = false
        model.emit 'hit', @
        @life = 0

  insertView: ->
    @view = ModeledView.fromState @game,
      type: 'ProjectileView'
      model: @

  getState: ->
    Object.assign super(),
      damage: @damage
      life: @life
      shipID: @ship.id
      speed: @speed

  setState: (state) ->
    super state
    {@damage, @life, @shipID, @speed} = state

  updateVelocity: -> # projectile velocity is constant

  update: ->
    super()
    @life--
    @delete 'because it died' unless @life > 0
