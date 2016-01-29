if require?
  Util = require './util'
  Ship = require './ship'

(module ? {}).exports = class InterpolatedShip extends Ship
  constructor: (@game, @params) ->
    return unless @game? and @params?.id
    @next = @params
    @setState @params
    @params.alwaysUpdate = true
    super @game, @params

  delete: ->
    super()
    Explosion.fromState @game, position: @position.slice(), true

  updateVelocity: -> # InterpolatedShip positions don't count on velocity

  updatePosition: ->
    rate = @game.interpolation.rate * @game.interpolation.step
    @position = Util.lerp @prev.position, @next.position, rate

  setState: (state) ->
    super state
    @prev =
      position: @next.position
      width: @next.velocity
      height: @next.height
      color: @next.color

    @next = state

  insertView: ->
    @view = new ShipView @, false
    console.log "Couldn't create view for interpolated ship", @id unless @view
    @view.update()
