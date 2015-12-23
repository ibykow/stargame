(module ? {}).exports = Util =
  toroidalDelta: (p0, p1, pLimit) ->
    return unless p0 and p1 and pLimit
    len = Math.min(Math.min(p0.length, p1.length), pLimit.length)
    return [] if len < 1

    for i in [0...len]
      delta = p0[i] - p1[i]
      adelta = Math.abs delta
      sign = 1
      if delta > 0
        sign *= -1

      if adelta > (pLimit[i] / 2)
        (pLimit[i] - adelta) * sign
      else
        delta

  findEmptySlot: (arr) ->
    return unless arr and Array.isArray arr
    for slot in [0..arr.length]
      return slot if not arr[slot]

  isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v

  indexOf: (arr, f) ->
    return -1 unless Array.isArray(arr) and
      arr.length and typeof f is 'function'

    return i if f(arr[i], i, arr) for i in [0...arr.length]
    return -1

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

  lerp: (p0, p1, rate) ->
    return p0 if rate <= 0
    return p1 if rate >= 1
    return p1 unless p1 and p0 and (len = Math.min p0.length, p1.length) > 0
    Math.trunc(((p1[i] - p0[i]) * rate + p0[i]) * 100) / 100 for i in [0...len]

  lerpAll: (points, rate) ->
    irate = 1 - rate
    for point in points when point.length > 1
      @lerp(point[0], point[1], rate, irate)
