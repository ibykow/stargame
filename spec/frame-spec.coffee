Util = require '../coffee/util'
Game = require '../coffee/game'
Frame = require '../coffee/frame'

describe 'Frame', ->
  [g, f] = []

  beforeEach ->
    g = new Game()

  describe '.new', ->
    it 'should create a new first frame', ->
      f = new Frame g
      expect(f).toBeDefined()
      expect(f.tick).toEqual 0
      expect(f.time).toEqual 0
      expect(f.dt).toEqual 0
      expect(f.state).toEqual {}
      expect(f.input).toEqual []

    it 'should create a new frame with the given attributes', ->
      state = {width: 10, height: 20, sprites: []}
      f = new Frame g, 160, 10, [], state

      expect(f).toBeDefined()
      expect(f.tick).toEqual 10
      expect(f.time).toEqual 160
      expect(f.dt).toEqual 0
      expect(f.state).toEqual state
      expect(f.input).toEqual []
