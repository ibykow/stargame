Config = require '../coffee/config'
RingBuffer = require '../coffee/ringbuffer'

describe 'RingBuffer', ->
  describe '.new', ->
    it 'creates a new ring buffer', ->
      ring = new RingBuffer 50
      expect(ring.max).toBe 50

      ring = new RingBuffer 3
      expect(ring.max).toBe 3

      ring = new RingBuffer
      expect(ring.max).toBe Config.common.ringbuffer.max

      ring = new RingBuffer 0
      expect(ring.max).toBe 0
      expect(ring.buffer).toBe undefined

      ring = new RingBuffer -1
      expect(ring.max).toBe -1
      expect(ring.buffer).toBe undefined

  describe '.insert', ->
    it 'should insert items into the array', ->
      ring = new RingBuffer 11

      for i in [1..10]
        ring.insert i
        expect(ring.buffer[i - 1]).toBe i
        expect(ring.length).toBe i
        expect(ring.head).toBe i

      ring.insert null
      expect(ring.head).toBe 10

      ring.insert 'abc'
      expect(ring.head).toBe 0

      for i in [1..10]
        ring.insert i + 5
        expect(ring.buffer[i - 1]).toBe i + 5
        expect(ring.head).toBe i

  describe '.remove', ->
    it 'should remove correct items from array', ->
      [startCharCode, stopCharCode] = [65, 90]
      length = stopCharCode - startCharCode + 1
      ring = new RingBuffer length
      ring.insert String.fromCharCode c for c in [startCharCode..stopCharCode]
      for c in [startCharCode..stopCharCode]
        expect(ring.length > 0).toBe true
        value = ring.remove()
        expect(value).toBe String.fromCharCode c

      expect(ring.remove()).toBeNull()

    it "shouldn't remove anything from empty arrays", ->
      ring = new RingBuffer
      expect(ring.remove()).toBe null

  describe '.peek', ->
    it 'should provide the item without removing it', ->
      ring = new RingBuffer 10
      string = 'Hello, World!'
      ring.insert string

      expect(ring.peek()).toBe string
      expect(ring.peek()).toBe string
      expect(ring.remove()).toBe string

  describe '.purge', ->
    it 'should purge all items that return true from function', ->
      ring = new RingBuffer 100
      for i in [5..50]
        ring.insert i

      ring.purge((n) -> n < 20)

      for i in [20..50]
        expect(ring.remove()).toBe i

      ring.reset()

      for i in [1..100]
        ring.insert i

      ring.purge((n) -> n < 50)

      for i in [50..100]
        expect(ring.remove()).toBe i

  describe '.map', ->
    it 'should apply a function to each entry and return the results', ->
      ring = new RingBuffer 50
      ring.insert i for i in [5..50]
      results = ring.map((n, i, arr) -> n *= n)

      expect(results[i - 5]).toBe(i * i) for i in [5..50]
      expect(ring.remove()).toBe i for i in [5..50]

    it 'should return an empty array when dealing with an empty ring', ->
      ring = new RingBuffer 50
      expect(ring.map((o) -> 1)).toEqual []

    it 'should return an full array when dealing with a full ring', ->
      ring = new RingBuffer 10
      ring.insert i + 5 for i in [1..10]

      expect(ring.map((n) -> n - 3)).toEqual [3,4,5,6,7,8,9,10,11,12]

    it 'should return an empty array when dealing with an insane ring', ->
      ring = new RingBuffer 50
      ring.insert i for i in [0..55]
      ring.head = 90
      expect(ring.map((o) -> 1)).toEqual []

  describe '.isSane', ->
    it 'should return true if empty and head and tail are between 0 and max', ->
      ring = new RingBuffer 20

      expect(ring.tail).toBe 0
      expect(ring.head).toBe 0

      expect(ring.isSane()).toBe true

      ring.tail = -1
      expect(ring.isSane()).toBe false

      ring.tail = 0
      expect(ring.isSane()).toBe true

      ring.tail = 50
      expect(ring.isSane()).toBe false

      ring.tail = 0
      expect(ring.isSane()).toBe true

      ring.head = -1
      expect(ring.isSane()).toBe false

      ring.head = 0
      expect(ring.isSane()).toBe true

      ring.head = 50
      expect(ring.isSane()).toBe false

      ring.head = 0
      expect(ring.isSane()).toBe true

      ring.tail = -1
      ring.head = 50
      expect(ring.isSane()).toBe false

      ring.tail = 0
      ring.head = 0
      expect(ring.isSane()).toBe true

      ring.tail = 50
      ring.head = -1
      expect(ring.isSane()).toBe false

    it 'should return true if full, and head equals tail between 0 and max', ->
      ring = new RingBuffer 20
      ring.insert i for i in [0..20]

      expect(ring.full).toBe true
      expect(ring.head).toBe ring.tail
      expect(ring.isSane()).toBe true

      ring.tail = -1
      ring.head = 50
      expect(ring.isSane()).toBe false

      ring.tail = 0
      ring.head = 0
      expect(ring.isSane()).toBe true

      ring.tail = 50
      ring.head = -1
      expect(ring.isSane()).toBe false
