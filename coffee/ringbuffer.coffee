if require?
  Config = require './config'
  Util = require './util'

[min] = [Math.min]

(module ? {}).exports = class RingBuffer
  constructor: (@max = Config.common.ringbuffer.max)->
    return if @max < 2
    @buffer = new Array @max
    @reset()

  reset: ->
    @head = 0
    @tail = 0
    @full = false
    @length = 0

  # purge elements while f returns true
  # f takes the current element as an argument
  purge: (check) ->
    return @reset() unless typeof check is 'function'
    @remove() while (data = @peek()) and check data

  find: (f) ->
    return unless typeof f is 'function'
    (return data if f data) while data = @peek()
    return null

  toArray: ->
    return [] unless @length and @isSane()

    if @head > @tail
      @buffer.slice @tail, @head
    else
      @buffer.slice(@tail, @max).concat @buffer.slice(0, @head)

  insert: (o) ->
    return unless o
    # if we're full, move the tail up to make room
    @tail = (@tail + 1) % @max if @full

    # insert the data at @head
    @buffer[@head] = o

    # increment @head
    @head = (@head + 1) % @max

    # initially, the buffer is empty and @head equals @tail,
    # so if @head equals @tail after insertion, the buffer must be full
    @full = @head is @tail
    @length++

  remove: ->
    # return null if buffer is empty
    return null if @length is 0

    # remember the item
    item = @buffer[@tail]

    # increment @tail
    @tail = (@tail + 1) % @max

    # the buffer can't be full since we've removed an item
    @full = false
    @length--

    return item

  # get the tail item without removing it
  peek: -> if @length is 0 then null else @buffer[@tail]

  map: (f) ->
    return [] if (@length is 0) or not @isSane()
    i = @tail
    for index in [0...@length]
      value = f @buffer[i], index, @
      i = (i + 1) % @max
      value

  isSane: ->
    (@tail >= 0) and (@tail < @max) and
    (@head >= 0) and (@head < @max) and
    ((@full and (@tail is @head)) or true)
