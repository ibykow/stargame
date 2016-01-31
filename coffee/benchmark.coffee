{max, min} = Math

(module ? {}).exports = class Benchmark
  @period: 300
  @getNamedFunctionsOf: (object = {}, except = ['constructor', 'toString']) ->
    names = []
    for name, prop of object when typeof prop is 'function'
      names.push name unless name in except

    return names

  constructor: (@target = {}) ->
    @stats = @target.stats or {}

    # Sanitize incoming stats
    stat.running = false for key, stat of @stats

    if process?.hrtime
      @source = 'process.hrtime'
      @ttime = -> process.hrtime()
      @tdiff = (t, t1) -> (t1[0] - t[0]) * 1e3 + ((t1[1] - t[1]) / 1e6)
    else if window?.performance?.now
      @source = 'window.performance.now'
      @ttime = -> window.performance.now()
    else
      @source = 'Date.now()'
      @ttime = -> Date.now()
      @_warn "Using " + @source + ". This isn't going to be very accurate."

    @wrap @target

  _fail: (message) -> Error "Benchmark: " + message

  _info: (message = 'Ping', args...) -> @_log_type message, 'INFO ', args...
  _log: (message, args...) -> @_log_type message, '', args...
  _warn: (message, args...) -> @_log_type message, 'WARNING ', args...
  _log_type: (message, type, args...) ->
    console.log 'Benchmark ' + type + '(' + (Date.now()) + '): ' + message,
      args...

  at: (key) ->
    @stats[key] ?=
      history: []
      index: 0
      key: key
      running: false

  bench: (callback, args...) -> @mark 'master', callback, args...

  getBlankResult: ->
    average:
      delta: 0
      max: 0
      min: 0
    delta: 0
    done: false
    max: 0
    min: 1e16
    start:
      source: 0
      time: 0
    stop:
      source: 0
      time: 0

  getResult: (key = 'master') ->
    stat = @stats[key]
    {history, result, running} = @stats[key] if stat?
    unless result? and (not running or history.length)
      return @_fail "No results for benchmark '" + key + "'."

    if running then return history[history.length - 1]
    return result

  mark: (key = 'master', callback, args...) ->
    return @_fail 'Function not provided' unless typeof callback is 'function'
    stat = @at key
    return callback args... if stat.running

    @start key
    result = callback args...
    @stop key
    return result

  getResultStrings: (result) ->
    for key in ['delta', 'min', 'max']
      result[key].toFixed(2) + '/' + result.average[key].toFixed(2)

  getStatStrings: (keys...) ->
    return unless keys.length

    for key in keys
      {history, index} = @at key
      continue unless result = history?[index]
      key + ': ' + @getResultStrings(result).join ', '

  process: (stat) ->
    return @_fail 'Nothing to process' unless result = stat?.result

    if result?.processed
      return @_fail "Cannot process the requested result for benchmark '" +
        stat.key + "' because it has already been processed."

    result.processed = true
    result.delta = @tdiff result.start.source, result.stop.source
    length = stat.history.length
    period = Benchmark.period

    if length
      head = stat.history[stat.index]
      nextIndex = stat.index + 1
      result.max = max head.max, result.delta
      result.min = min head.min, result.delta
      if length is period
        nextIndex %= period
        tail = stat.history[nextIndex]
        newDelta = (result.delta - tail.delta) / period
        result.average.delta = newDelta + head.average.delta
      else
        newSum = head.average.delta * length + result.delta
        result.average.delta = newSum / (length + 1)
      result.average.max = max result.average.delta, head.average.max
      result.average.min = min result.average.delta, head.average.min
      stat.index = nextIndex
    else
      result.max = result.delta
      result.min = result.delta
      result.average.delta = result.delta
      result.average.max = result.delta
      result.average.min = result.delta

    stat.history[stat.index] = result
    return result.delta

  reset: -> @stats = {}

  start: (key = 'master') ->
    stat = @at key
    return @_fail "'" + key + "' is already running." if stat.running

    stat.running = true
    stat.result = @getBlankResult()

    # Start the timers last to maximize accuracy
    stat.result.start.time = Date.now()

    # The highest resolution timer should start last and stop first
    stat.result.start.source = @ttime()

  stop: (key = 'master') ->
    # Grab the time right away to maximize accuracy
    source = @ttime()
    time = Date.now()

    # Sanitize
    unless (stat = @stats[key]) and stat.running and not stat.result.processed
      return @_fail "'" + key + "' has not been started."

    # Process result
    stat.running = false
    stat.result.stop.source = source
    stat.result.stop.time = time
    @process stat

  tdiff: (t, t1) -> t1 - t

  # wrap: Wrap's an object's methods with a call to @mark
  # @target: the target object
  # @methodNames: the names of the functions to wrap
  wrap: (target, names) ->
    return @_fail 'Cannot wrap unspecified target.' unless target?
    names ?= Benchmark.getNamedFunctionsOf target
    return unless names
    target._benchmarkFunctions ?= {}
    _mark = @mark.bind @
    for name in names
      # Ignore non-existent functions
      unless typeof target[name] is 'function'
        @_warn "Cannot wrap '" + name + "'. It is not a function."
        continue

      if target._benchmarkFunctions[name]
        @_warn "'" + name + "' has already been wrapped."
        continue

      # Store the original function and replace it in the target
      original = target[name]
      target._benchmarkFunctions[name] = original
      bound = (n, t, o, a...) -> @mark n, o.bind t, a...
      bound = bound.bind @, name, target, original
      target[name] = bound

  # Unwrap some or all of the target's functions
  unwrap: (target, methodNames = []) ->
    return @_fail 'No target was specified for unwrapping.' unless target?
    if methodNames.length
      for name in methodNames
        unless orignal = target._benchmarkFunctions[name]
          @_warn "Could not unwrap '" + name + "'. Original not found."
          continue
        target[name] = target._benchmarkFunctions[name]
        delete target._benchmarkFunctions[name]
    else
      for name of target._benchmarkFunctions
        target[name] = target._benchmarkFunctions[name]
        delete target._benchmarkFunctions[name]

    functionsRemaining = Object.keys(target._benchmarkFunctions)?.length
    delete target['_benchmarkFunctions'] unless functionsRemaining
