if require?
  Util = require './util'

isnum = Util.isNumeric
{max} = Math

(module ? {}).exports = class Timer
  @nextID: 1
  @pool: {}
  @flush: ->
    @nextID = 1
    @pool = {}

  @run: (step) ->
    # create a place to store ids whose timers don't repeat
    deleted = []
    for id, timer of Timer.pool when timer.isActive
      timer.remaining = timer.nextStep - step
      continue if timer.remaining > 0
      # run the callback
      timer.callback()
      if timer.repeats then timer.nextStep += timer.period else deleted.push id

    # delete timers
    delete Timer.pool[id] for id in deleted

  constructor: (@start, @period, @callback, @repeats = false) ->
    return unless (typeof @callback is 'function') and
      isnum(@start) and (@start >= 0) and
      isnum(@period) and (@period > 0)

    @args ?= []
    @isActive = true
    @remaining = @period
    @nextStep = @start + @period
    @id = Timer.nextID
    Timer.nextID++
    Timer.pool[@id] = @

  getRemaining: (step) -> max step - @nextStep, 0

  delete: ->
    return unless Timer.pool[@id]
    @callback = ->
    @args = []
    @target = @
    @isActive = true
    @nextStep = 0
