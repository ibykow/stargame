if require?
  Config = require './config'
  Util = require './util'

[min] = [Math.min]

(module ? {}).exports = class RingBuffer
  constructor: (@max = Config.common.ringbuffer.max)->
    return if @max < 2
    @data = new Array @max
    @reset()

  reset: ->
    @head = 0
    @tail = 0
    @full = false
    @length = 0

  # purge elements while f returns true
  # f takes the current element as an argument
  purge: (f) ->
    if typeof f is 'function'
      while (o = @peek()) and (f(o) is true)
        @remove()
    else
      @reset()

  find: (f) ->
    return unless typeof f is 'function'

    while o = @peek()
      return o if f(o)

    null

  isEmpty: ->
    @length is 0 # @head is @tail and not @full

  toArray: ->
    return [] if @isEmpty()

    if @head > @tail
      @data.slice @tail, @head
    else
      @data.slice(@tail, @max).concat @data.slice(0, @head)

  insert: (o) ->
    return unless o
    # if we're full, move the tail up to make room
    @tail = (@tail + 1) % @max if @full

    # insert the data at @head
    @data[@head] = o

    # increment @head
    @head = (@head + 1) % @max

    # initially, the buffer is empty and @head equals @tail,
    # so if @head equals @tail after insertion, the buffer must be full
    @full = @head is @tail

    @length++

  remove: ->
    # return null if buffer is empty
    return null if @isEmpty()

    # take the item
    item = @data[@tail]

    # increment @tail
    @tail = (@tail + 1) % @max

    # the buffer can't be full since we've removed an item
    @full = false
    @length--
    # return the item
    item

  peek: ->
    # get the tail item without removing it
    if @isEmpty() then null else @data[@tail]

  map: (f) ->
    return [] if @isEmpty() or not @isSane()
    i = @tail
    index = 0
    while not (index is @length)
      ret = f @data[i], index, @
      i = (i + 1) % @max
      index++
      ret

  isSane: ->
    (@tail >= 0) and (@tail < @max) and
    (@head >= 0) and (@head < @max) and
    ((@full and (@tail is @head)) or true)
