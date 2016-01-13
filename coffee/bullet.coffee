if require?
  Config = require './config'
  Util = require './util'
  Physical = require './physical'

{ceil, cos, sin} = Math
{damage, life, speed} = Config.common.bullet

(module ? {}).exports = class Bullet extends Physical
  constructor: (@game, @params) ->
    return unless @game?
    @ship = @game.lib['Ship']?[@params?.shipID]
    @ship ?= @game.lib['InterpolatedShip']?[@params?.shipID]
    return console.log "Couldn't create bullet. Ship not found." unless @ship

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

    @params.v0 = [xdir * @speed, ydir * @speed]
    @params.position = [  @ship.position[0] + xdir * (@ship.width + 2),
                          @ship.position[1] + ydir * (@ship.height + 2),
                          @ship.position[2] ]

    super @game, @params

  delete: ->
    @game.deadBulletIDs.push @id
    @life = 0
    super()

  initEventHandlers: ->
    super()
    # collision detection
    handler = @now 'move', (data, handler) =>
      return if @deleted
      for id, model of @game.around @partition when not (model.id is @id)
        if @intersects model
          handler.repeats = false
          model.emit 'hit', @

  getState: ->
    Object.assign super(),
      damage: @damage
      life: @life
      shipID: @ship.id
      speed: @speed

  setState: (state) ->
    super state
    {@damage, @life, @shipID, @speed} = state

  updateVelocity: -> # bullet velocity is constant

  update: ->
    super()
    @life--
    @delete() unless @life > 0
