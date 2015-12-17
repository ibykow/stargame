Util = require '../coffee/util'
Game = require '../coffee/game'

describe 'Game', ->
  [game] = []
  describe '.new', ->
    it 'creates a new game', ->
      game = new Game(1000, 1200)
      expect(game).not.toBeNull()

      expect(game.width).toEqual(1000)
      expect(game.height).toEqual(1200)

      expect(game.players).toBeDefined()
      expect(game.players.length).toEqual 0

  describe 'instance methods', ->
    [width, height] = [333, 555]
    beforeEach: ->
      game = new Game(widht, height)

    describe '.randomPostion', ->
      it "generates a random position within the game's bounds", ->
        for i in [1..1000]
          position = game.randomPosition()
          expect(position[0]).not.toBeLessThan 0
          expect(position[0]).toBeLessThan game.width
          expect(position[1]).not.toBeLessThan 0
          expect(position[1]).toBeLessThan game.height

    describe '.serialize', ->
      it 'serializes the game state', ->
        state = game.serialize()
        expect(state.width).toEqual game.width
        expect(state.height).toEqual game.height

        expect(state.players).toBeDefined()
        expect(state.players.length).toEqual(game.players.length)

    describe '.patch', ->
      it 'updates the game to to reflect values in the patch', ->
        state = { width: 960, height: 120 }
        game.patch(state)
        expect(game.width).toEqual 960
        expect(game.height).toEqual 120
