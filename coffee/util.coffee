[floor, isarr, min, max, rnd, trunc] =
  [Math.floor, Array.isArray, Math.min, Math.max, Math.random, Math.trunc]

(module ? {}).exports = Util =
  vectorDeltaExists: (a, b) ->
    # Returns true if only one is an array, or if the arrays are
    # of differnt lengths. Returns false if neither are arrays.

    if isarr a
      return true unless (isarr b) and (a.length is b.length)
    else
      if isarr b then return true else return false

    # look for a difference in the values
    return true unless a[i] is b[i] for i in [0...a.length]

    # return false when no difference is found
    false

  areSquareBoundsOverlapped: (a, b) ->
    # check if square bounds are overlapped
    return unless isarr(a) and isarr(b)

    for i in [0...a[0].length]
      if a[0][i] < b[0][i]
        return false if b[0][i] - a[0][i] > a[1][i]
      else
        return false if a[0][i] - b[0][i] > a[1][i]

    true

  isInSquareBounds: (point, bounds) ->
    return unless isarr(point) and isarr(bounds) and
      bounds.length is 2

    len = min(min(bounds[0].length, bounds[1].length), point.length)

    for i in [0...len]
      delta = point[i] - bounds[0][i]
      return false if delta < 0 or delta > bounds[1][i]

    true

  toroidalDelta: (p0, p1, pLimit) ->
    return unless p0 and p1 and pLimit
    len = min(min(p0.length, p1.length), pLimit.length)
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
    return unless arr and isarr arr
    for slot in [0..arr.length]
      return slot if not arr[slot]

  isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v

  indexOf: (arr, f) ->
    return -1 unless isarr(arr) and
      arr.length and typeof f is 'function'

    return i if f(arr[i], i, arr) for i in [0...arr.length]
    return -1

  randomInt: (min = 0, max = 99) ->
    return floor(rnd() * (max - min) + min)

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
    return p1 unless p1 and p0 and (len = min p0.length, p1.length) > 0
    trunc(((p1[i] - p0[i]) * rate + p0[i]) * 100) / 100 for i in [0...len]

  lerpAll: (points, rate) ->
    irate = 1 - rate
    for point in points when point.length > 1
      @lerp(point[0], point[1], rate, irate)
