{abs, floor, max, min, sqrt, trunc} = Math

rnd = Math.random
pi = Math.PI
isarr = Array.isArray

(module ? {}).exports = Util =
  PI: pi
  TWO_PI: pi * 2

  # Returns a list of keys which differ between objects
  diff: (a, b) ->
    results = []
    (results.push key unless value is b[key]) for key, value of a
    (results.push key unless a[key]?) for key, value of b
    return results

  getByType: (items, type) ->
    return [] unless Object.keys(items).length and (typeof type is 'string')
    results = []
    (results.push item if item.type is type) for id, item of items
    return results

  filterChildrenByType: (list, type) ->
    return [] unless (isarr list)
    ret = []
    (ret = ret.concat @getByType emitter.children, type) for emitter in list
    return ret

  vectorDeltaExists: (a, b) ->
    # Returns true if only one is an array, or if the arrays are
    # of differnt lengths. Returns false if neither are arrays.

    if isarr a
      return true unless (isarr b) and (a.length is b.length)
    else
      if isarr b then return true else return false

    # look for a difference in the values
    for i in [0...a.length]
      return true unless a[i] is b[i]

    # return false when no difference is found
    false

  isInSquareBounds: (point, bounds) ->
    return unless isarr(point) and isarr(bounds) and
      bounds.length is 2

    len = min min(bounds[0].length, bounds[1].length), point.length

    for i in [0...len]
      delta = point[i] - bounds[0][i]
      return false if delta < 0 or delta > bounds[1][i]

    true

  toroidalDelta: (p0, p1, pLimit) ->
    return unless isarr(p0) and isarr(p1) and isarr(pLimit)
    dx = p0[0] - p1[0]
    dy = p0[1] - p1[1]

    adx = abs dx
    ady = abs dy

    if dx > 0 then signx = -1 else signx = 1
    if dy > 0 then signy = -1 else signy = 1

    dx = (pLimit[0] - adx) * signx if adx > (pLimit[0] / 2)
    dy = (pLimit[1] - ady) * signy if ady > (pLimit[1] / 2)

    [dx, dy]

  # sqrt v.reduce (a, b) -> a + b * b
  magnitude: (v = [0]) -> sqrt v[0] * v[0] + v[1] * v[1]

  findEmptySlot: (arr) ->
    return unless isarr arr
    for slot in [0..arr.length]
      return slot if not arr[slot]

  isNumeric: (v) ->
    not isNaN(parseFloat(v)) and isFinite v

  indexOf: (arr, f) ->
    return -1 unless isarr(arr) and
      arr.length and typeof f is 'function'

    return i if f(arr[i], i, arr) for i in [0...arr.length]
    return -1

  randomInt: (min = 0, max = 99) -> floor rnd() * (max - min) + min

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
