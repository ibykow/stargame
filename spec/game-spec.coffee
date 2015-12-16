Game = require '../coffee/game'

describe 'Game', ->
  [game] = []

  describe '.randomInt', ->
    it 'generates a random integer within a range', ->
      [min, max] = [10, 20]
      for i in [1..10000]
        n = Game.randomInt(min, max)
        expect(Number.isInteger n).toBe true
        expect(n).toBeLessThan max
        expect(n).not.toBeLessThan min

  describe '.padString', ->
    it 'pads a string up to a specified length', ->
      s = '12345'
      expect(Game.padString(s, 6, '0')).toBe '0' + s
      expect(Game.padString(s, 12, '0')).toBe '0000000' + s
      expect(Game.padString(s, 1, '0')).toBe s
      expect(Game.padString(s, 2, '0')).toBe s
      expect(Game.padString(s, 3, '0')).toBe s
      expect(Game.padString(s, 4, '0')).toBe s
      expect(Game.padString(s, 5, '0')).toBe s
      expect(Game.padString(null, 5, '0')).toBe ''

      for i in [1..1000]
        s = Game.padString(Game.randomInt(0, 0xff).toString 16)
        expect(s.length).toBeLessThan 3

  describe '.randomColorString', ->
    it 'returns a string in the form "#rrggbb" where r, g, b are hex color values', ->
      [min, max] = [100, 0xff]

      for attemp in [1..1000]
        s = Game.randomColorString min, max
        expect(typeof s).toBe 'string'
        expect(s[0]).toBe '#'
        expect(s.length).toBe 7

        n = parseInt(s.substring(1), 16)
        expect(n).toBeLessThan 0xFFFFFF

        # verify leftmost (red) octet
        n1 = n >> 16
        expect(n1).not.toBeLessThan min
        expect(n1).toBeLessThan max

        # verify middle (green) octet
        n1 = (n - (n1 << 16)) >> 8
        expect(n1).not.toBeLessThan min
        expect(n1).toBeLessThan max

        # verify rightmost (blue) octet
        n1 = n - ((n >> 8) << 8)
        expect(n1).not.toBeLessThan min
        expect(n1).toBeLessThan max


  describe '.isNumeric', ->
    it 'tells if the input is a kind of number', ->
      expect(Game.isNumeric(3)).toBe true
      expect(Game.isNumeric(0)).toBe true
      expect(Game.isNumeric(0.01)).toBe true
      expect(Game.isNumeric(1.1)).toBe true
      expect(Game.isNumeric(100000)).toBe true
      expect(Game.isNumeric(Math.sqrt(2))).toBe true
      expect(Game.isNumeric(Math.PI)).toBe true
      expect(Game.isNumeric(-324.23423)).toBe true
      expect(Game.isNumeric('3.5')).toBe true

      v = 23
      expect(Game.isNumeric(v)).toBe true

      expect(Game.isNumeric('fred')).toBe false
      expect(Game.isNumeric(NaN)).toBe false

      v = []
      expect(Game.isNumeric(v)).toBe false
      expect(Game.isNumeric(null)).toBe false

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
