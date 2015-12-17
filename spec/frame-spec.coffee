Util = require '../coffee/util'
Game = require '../coffee/game'
Frame = require '../coffee/frame'

describe 'Frame', ->
  [game, frame] = []
  state = {width: 640, height: 480, players: [], sprites: [] }

  beforeEach ->
    game = new Game(state.width, state.height)

  describe '.new', ->
    it 'should create a new first frame', ->
      frame = new Frame game
      expect(frame).toBeDefined()
      expect(frame.tick).toBeDefined()
      expect(frame.tick.count).toEqual 1
      expect(frame.tick.time).toEqual 0
      expect(frame.tick.dt).toEqual 0
      expect(frame.state).toEqual state
      expect(frame.inputs).toEqual []
