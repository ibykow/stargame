Util = require '../coffee/util'

describe 'Util', ->
  describe '.randomInt', ->
    it 'generates a random integer within a range', ->
      [min, max] = [10, 20]
      for i in [1..10000]
        n = Util.randomInt(min, max)
        expect(Number.isInteger n).toBe true
        expect(n).toBeLessThan max
        expect(n).not.toBeLessThan min
    it 'generates a random integer between negative and positive'
      [min, max] = [-2, 10]

  describe '.padString', ->
    it 'pads a string up to a specified length', ->
      s = '12345'
      expect(Util.padString(s, 6, '0')).toBe '0' + s
      expect(Util.padString(s, 12, '0')).toBe '0000000' + s
      expect(Util.padString(s, 1, '0')).toBe s
      expect(Util.padString(s, 2, '0')).toBe s
      expect(Util.padString(s, 3, '0')).toBe s
      expect(Util.padString(s, 4, '0')).toBe s
      expect(Util.padString(s, 5, '0')).toBe s
      expect(Util.padString(null, 5, '0')).toBe ''

      for i in [1..1000]
        s = Util.padString(Util.randomInt(0, 0xff).toString 16)
        expect(s.length).toBeLessThan 3

  describe '.randomColorString', ->
    it 'returns a string in the form "#rrggbb" where r, g, b are hex color values', ->
      [min, max] = [100, 0xff]

      for attemp in [1..1000]
        s = Util.randomColorString min, max
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
      expect(Util.isNumeric(3)).toBe true
      expect(Util.isNumeric(0)).toBe true
      expect(Util.isNumeric(0.01)).toBe true
      expect(Util.isNumeric(1.1)).toBe true
      expect(Util.isNumeric(100000)).toBe true
      expect(Util.isNumeric(Math.sqrt(2))).toBe true
      expect(Util.isNumeric(Math.PI)).toBe true
      expect(Util.isNumeric(-324.23423)).toBe true
      expect(Util.isNumeric('3.5')).toBe true

      v = 23
      expect(Util.isNumeric(v)).toBe true

      expect(Util.isNumeric('fred')).toBe false
      expect(Util.isNumeric(NaN)).toBe false

      v = []
      expect(Util.isNumeric(v)).toBe false
      expect(Util.isNumeric(null)).toBe false
