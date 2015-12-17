(module ? {}).exports = class Tick
  constructor: (@time = 0, previousTick = { count: 0, time: 0}) ->
    @count = previousTick.count + 1
    @dt = @time - previousTick.time
