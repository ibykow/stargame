Util = require '../coffee/util'
Game = require '../coffee/game'
Tick = require '../coffee/tick'

describe 'Tick', ->
  [tick] = []

  beforeEach ->
    tick = new Tick()

  describe '.new', ->
    it 'creates a new first tick', ->
      expect(tick).toBeDefined()
      expect(tick.count).toEqual 0
      expect(tick.time).toEqual 0
      expect(tick.dt).toEqual 0

    it 'creates new ticks based on previous ticks', ->
      time = 16
      lastTime = 0

      for i in [1..100]
        tick = new Tick(time, tick)

        expect(tick).toBeDefined()
        expect(tick.count).toEqual i
        expect(tick.time).toEqual time
        expect(tick.dt).toEqual time - lastTime

        lastTime = time
        time = 16 + Math.floor(Math.random() * 3) - 1
