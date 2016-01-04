(module ? {}).exports = class Timer
  @nextID: 0
  @timers: {}
  @run: (step) ->
    # create a place to store ids whose timers don't repeat
    deleted = []
    for id, timer of @timers when timer.isActive and (timer.nextStep <= step)
      # run the callback
      timer.callback.bind(timer.target) timer.args...
      if timer.repeats then timer.nextStep += timer.period else deleted.push id

    # delete timers
    delete @timers[id] for id in deleted

  constructor: (@start, @period, @callback, @repeats = false, @target, @args) ->
    return unless (typeof @callback is 'function') and
      isnum(@start) and (@start >= 0) and
      isnum(@period) and (@period > 0)

    @args ?= []
    @isActive = true
    @nextStep = @start + @period
    @nextID++
    @id = @nextID
    @timers[@nextID] = @

  delete: ->
    return unless @timers[@id]
    @callback = ->
    @args = []
    @target = @
    @isActive = true
    @nextStep = 0
