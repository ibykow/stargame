if require?
  Util = require './util'
  Ship = require './ship'

(module ? {}).exports = class InterpolatedShip extends Ship
  constructor: (@game, @params = {}) ->
    return unless @game? and @params?.id
    @next = @params
    @setState @params
    super @game, @params

  updateVelocity: -> # InterpolatedShip positions don't count on velocity

  updatePosition: ->
    rate = @game.interpolation.rate * @game.interpolation.step
    @position = Util.lerp @prev.position, @next.position, rate
    @rotation = Util.lerp([@prev.rotation], [@next.rotation], rate)[0]

  setState: (state) ->
    super state
    @prev =
      position: @next.position
      rotation: @next.rotation
      width: @next.velocity
      height: @next.height
      color: @next.color

    @next = state

  insertView: ->
    @view = new ShipView @game, model: @
    console.log "Couldn't create view for interpolated ship", @id unless @view
    @view.update()
