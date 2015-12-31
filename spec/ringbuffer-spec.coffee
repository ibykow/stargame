RingBuffer = require '../coffee/ringbuffer'

describe 'RingBuffer', ->
  describe '.new', ->
    it 'creates a new ring buffer', ->
      buffer = new RingBuffer 50
      expect(buffer.max).toBe 50

      buffer = new RingBuffer 3
      expect(buffer.max).toBe 3

      buffer = new RingBuffer
      expect(buffer.max).toBe RingBuffer.DEFAULT_MAX

      buffer = new RingBuffer 0
      expect(buffer.max).toBe 0
      expect(buffer.data).toBe undefined

      buffer = new RingBuffer -1
      expect(buffer.max).toBe -1
      expect(buffer.data).toBe undefined

  describe '.insert', ->
    it 'should insert items into the array', ->
      buffer = new RingBuffer 11

      for i in [1..10]
        buffer.insert i
        expect(buffer.data[i - 1]).toBe i
        expect(buffer.head).toBe i

      buffer.insert null
      expect(buffer.head).toBe 10

      buffer.insert 'abc'
      expect(buffer.head).toBe 0

      for i in [1..10]
        buffer.insert i + 5
        expect(buffer.data[i - 1]).toBe i + 5
        expect(buffer.head).toBe i

  describe '.remove', ->
    it 'should remove correct items from array', ->
      [startCharCode, stopCharCode] = [65, 90]
      buffer = new RingBuffer stopCharCode - startCharCode + 1
      for i in [startCharCode..stopCharCode]
        buffer.insert String.fromCharCode(i)

      for i in [startCharCode..stopCharCode]
        expect(buffer.remove()).toBe String.fromCharCode(i)

      expect(buffer.remove()).toBeNull()

    it "shouldn't remove anything from empty arrays", ->
      buffer = new RingBuffer
      expect(buffer.remove()).toBe null

  describe '.peek', ->
    it 'should provide the item without removing it', ->
      buffer = new RingBuffer 10
      string = 'Hello, World!'
      buffer.insert string

      expect(buffer.peek()).toBe string
      expect(buffer.peek()).toBe string
      expect(buffer.remove()).toBe string

  describe '.purge', ->
    it 'should purge all items that return true from function', ->
      buffer = new RingBuffer 100
      for i in [5..50]
        buffer.insert i

      buffer.purge((n) -> n < 20)

      for i in [20..50]
        expect(buffer.remove()).toBe i

      buffer.reset()

      for i in [1..100]
        buffer.insert i

      buffer.purge((n) -> n < 50)

      for i in [50..100]
        expect(buffer.remove()).toBe i

  describe '.map', ->
    it 'should apply a function to each entry and return the results', ->
      buffer = new RingBuffer 50
      buffer.insert i for i in [5..50]
      results = buffer.map((n, i, arr) -> n *= n)

      expect(results[i - 5]).toBe(i * i) for i in [5..50]
      expect(buffer.remove()).toBe i for i in [5..50]
