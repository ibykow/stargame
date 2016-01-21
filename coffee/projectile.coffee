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

    return console.log "WARNING! No ship, no projectile." unless @ship?

    {@damage, @life, @speed} = @params

    @damage ?= damage
    @life ?= life
    @speed ?= speed

    @params.width = @params.height = 2
    @params.color = @params.color ? '#FFD'

    vx = @ship.velocity[0]
    vy = @ship.velocity[1]
    xdir = cos @ship.position[2]
    ydir = sin @ship.position[2]

    @params.velocity = [xdir * @speed, ydir * @speed]
    @params.position = [  @ship.position[0] + xdir * (@ship.width + 2),
                          @ship.position[1] + ydir * (@ship.height + 2),
                          @ship.position[2] ]

    @params.alwaysUpdate = @params.alwaysUpdate ? true

    super @game, @params

  delete: ->
    @game.deadProjectileIDs.push @id
    @life = 0
    super()

  initEventHandlers: ->
    super()

    events =
      now:
        hit:
          bind: [@]
          timer: 0
          repeats: true
          callback: (model) -> @life -= model.damage

        move:
          bind: [@]
          timer: 0
          repeats: true
          callback: (data, handler) ->
            return if @deleted
            models = @around 1
            for model in models when not (model.id is @id) and @intersects model
              handler.repeats = false
              model.emit 'hit', @

    (@[type] name, info for name, info of event) for type, event of events

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
    @delete() unless @life > 0
