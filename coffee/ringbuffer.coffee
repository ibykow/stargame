if require?
  Util = require './util'

(module ? {}).exports = class RingBuffer
  @DEFAULT_MAX: 50
  constructor: (@max = RingBuffer.DEFAULT_MAX)->
    return if @max < 2
    @data = new Array @max
    @reset()

  reset: ->
    @head = 0
    @tail = 0
    @full = false

  # purge elements while f returns true
  # f takes the current element as an argument
  purge: (f) ->
    if typeof f is 'function'
      while (o = @peek()) and f(o)
        @remove()
    else
      @reset()

  find: (f) ->
    return unless typeof f is 'function'

    while o = @peek()
      return o if f(o)

    null

  isEmpty: ->
    @head is @tail and not @full

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

  remove: ->
    # return null if buffer is empty
    return null if @isEmpty()

    # take the item
    item = @data[@tail]

    # increment @tail
    @tail = (@tail + 1) % @max

    # the buffer can't be full since we've removed an item
    @full = false

    # return the item
    item

  peek: ->
    # get the tail item without removing it
    if @isEmpty() then null else @data[@tail]
