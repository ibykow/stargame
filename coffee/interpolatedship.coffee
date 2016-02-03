if require?
  Util = require './util'
  Ship = require './ship'

(module ? {}).exports = class InterpolatedShip extends Ship
  constructor: (@game, @params = {}) ->
    return unless @game? and @params?.id
    @next = @params
    @setState @params
    super @game, @params

  initHandlers: -> # Don't interract with collisions on client-side
  updateVelocity: -> # InterpolatedShip positions don't count on velocity

  updatePosition: ->
    [x, y] = @position
    rate = @game.interpolation.rate * @game.interpolation.step
    @position = Util.lerp @prev.position, @next.position, rate
    @rotation = Util.lerp([@prev.rotation], [@next.rotation], rate)[0]
    unless (x is @position[0]) and (y is @position[1])
      @updatePartition()
      @emit 'move', [x, y]

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
