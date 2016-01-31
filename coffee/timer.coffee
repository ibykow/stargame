if require?
  Util = require './util'

{max} = Math
isarr = Array.isArray
isnum = Util.isNumeric

(module ? {}).exports = class Timer
  @nextID: 1
  @now: 0
  @pool: {}
  @flush: ->
    @nextID = 1
    @pool = {}

  @run: (step) ->
    @now = step
    # create a place to store ids whose timers don't repeat
    deleted = []
    for id, timer of Timer.pool when timer.isActive
      timer.remaining = timer.nextStep - step
      continue if timer.remaining > 0
      if timer.deleted
        deleted.push id
        continue
      # run the callback
      timer.callback timer
      if timer.repeats then timer.nextStep += timer.period else deleted.push id

    # delete timers
    for id in deleted
      Timer.pool[id].deleted = true
      delete Timer.pool[id]

  constructor: (@period, @callback, @repeats = false) ->
    return unless typeof @callback is 'function'

    @deleted = false
    @id = Timer.nextID
    @isActive = true
    @nextStep = Timer.now + @period
    @remaining = @period
    Timer.nextID++
    Timer.pool[@id] = @

  getRemaining: (step) -> max step - @nextStep, 0

  delete: ->
    return unless Timer.pool[@id]
    console.log 'Deleting timer ' + @id
    @callback = ->
    @deleted = true
    @nextStep = 0
