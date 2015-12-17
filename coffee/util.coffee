(module ? {}).exports = Util =
  findEmptySlot: (arr) ->
    return unless arr and Array.isArray arr
    for slot in [0..arr.length]
      return slot if not arr[slot]

  isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v

  randomInt: (min = 0, max = 99) ->
    return Math.floor(Math.random() * (max - min) + min)

  padString: (s, n = 2, p = '0') ->
    return '' unless s and typeof s is 'string'
    len = n - s.length
    return s if len <= 0
    (p for [1..len]).join('') + s

  randomColorString: (min = 0xff >> 1, max = 0xff) ->
    '#' + Util.padString(Util.randomInt(min, max).toString 16) +
      Util.padString(Util.randomInt(min, max).toString 16) +
      Util.padString(Util.randomInt(min, max).toString 16)
