# TODO: add tests for multiple timers
Timer = require '../coffee/timer'

describe 'Timer', ->
  [start, period, repeats, counter, timer] = [50, 10, false, 0, null]

  callback = -> counter++

  beforeEach ->
    timer = new Timer start, period, callback, repeats
    counter = 1

  afterEach ->
    Timer.pool = {}
    Timer.nextID = 1

  describe '.new', ->
    it 'creates a new timer', ->
      expect((Object.keys Timer.pool).length).toBe 1
      expect(timer.start).toBe start
      expect(timer.period).toBe period
      expect(timer.callback).toBe callback
      expect(timer.repeats).toBe repeats
      expect(timer.id).toBe 1
      expect(timer.isActive).toBe true
      expect(timer.nextStep).toBe start + period
      expect(counter).toBe 1
      expect(Timer.pool[timer.id]).toBe timer
      expect(Timer.nextID).toBe 2

    it 'should increment Timer.nextID', ->
      for i in [2..10]
        expect(Timer.nextID).toBe i
        t = new Timer start, period, callback, repeats
        expect(t.id).toBe i

  describe '.delete', ->
    it 'removes a timer and prevents the callback from running', ->
      expect(timer).toBeDefined()
      expect(counter).toBe 1
      timer.delete()
      Timer.run start + period
      expect(Timer.pool[timer.id]).not.toBeDefined()
      expect(counter).toBe 1

  describe 'Timer.run', ->
    it 'should run the timer callback once', ->
      expect(timer).toBeDefined()
      expect(counter).toBe 1
      Timer.run timer.nextStep - 1
      expect(counter).toBe 1
      Timer.run timer.nextStep
      expect(Timer.pool[timer.id]).not.toBeDefined()
      expect(counter).toBe 2

    it 'should run the timer callback on repeat', ->
      timer.repeats = true
      for i in [2..10]
        Timer.run timer.nextStep
        expect(Timer.pool[timer.id]).toBeDefined()
        expect(counter).toBe i
        Timer.run timer.nextStep - 1
        expect(counter).toBe i

  describe 'Timer.flush', ->
    it 'should remove all timers and reset Timer.nextID', ->
      expect(Timer.pool).not.toEqual {}
      expect(Timer.nextID).toBe 2
      Timer.flush()
      expect(Timer.pool).toEqual {}
      expect(Timer.nextID).toBe 1
