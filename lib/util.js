var Util, abs, floor, isarr, max, min, ref, rnd, trunc;

ref = [Math.abs, Math.floor, Array.isArray, Math.min, Math.max, Math.random, Math.trunc], abs = ref[0], floor = ref[1], isarr = ref[2], min = ref[3], max = ref[4], rnd = ref[5], trunc = ref[6];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Util = {
  vectorDeltaExists: function(a, b) {
    var i;
    if (isarr(a)) {
      if (!((isarr(b)) && (a.length === b.length))) {
        return true;
      }
    } else {
      if (isarr(b)) {
        return true;
      } else {
        return false;
      }
    }
    if (!(function() {
      var j, ref1, results;
      results = [];
      for (i = j = 0, ref1 = a.length; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
        results.push(a[i] === b[i]);
      }
      return results;
    })()) {
      return true;
    }
    return false;
  },
  isInSquareBounds: function(point, bounds) {
    var delta, i, j, len, ref1;
    if (!(isarr(point) && isarr(bounds) && bounds.length === 2)) {
      return;
    }
    len = min(min(bounds[0].length, bounds[1].length), point.length);
    for (i = j = 0, ref1 = len; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
      delta = point[i] - bounds[0][i];
      if (delta < 0 || delta > bounds[1][i]) {
        return false;
      }
    }
    return true;
  },
  toroidalDelta: function(p0, p1, pLimit) {
    var adelta, delta, i, j, len, ref1, results, sign;
    if (!(isarr(p0) && isarr(p1) && isarr(pLimit))) {
      return;
    }
    len = min(min(p0.length, p1.length), pLimit.length);
    if (len < 1) {
      return [];
    }
    results = [];
    for (i = j = 0, ref1 = len; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
      delta = p0[i] - p1[i];
      adelta = Math.abs(delta);
      sign = 1;
      if (delta > 0) {
        sign *= -1;
      }
      if (adelta > (pLimit[i] / 2)) {
        results.push((pLimit[i] - adelta) * sign);
      } else {
        results.push(delta);
      }
    }
    return results;
  },
  findEmptySlot: function(arr) {
    var j, ref1, slot;
    if (!isarr(arr)) {
      return;
    }
    for (slot = j = 0, ref1 = arr.length; 0 <= ref1 ? j <= ref1 : j >= ref1; slot = 0 <= ref1 ? ++j : --j) {
      if (!arr[slot]) {
        return slot;
      }
    }
  },
  isNumeric: function(v) {
    return !isNaN(parseFloat(v)) && isFinite(v);
  },
  indexOf: function(arr, f) {
    var i;
    if (!(isarr(arr) && arr.length && typeof f === 'function')) {
      return -1;
    }
    if ((function() {
      var j, ref1, results;
      results = [];
      for (i = j = 0, ref1 = arr.length; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
        results.push(f(arr[i], i, arr));
      }
      return results;
    })()) {
      return i;
    }
    return -1;
  },
  randomInt: function(min, max) {
    if (min == null) {
      min = 0;
    }
    if (max == null) {
      max = 99;
    }
    return floor(rnd() * (max - min) + min);
  },
  padString: function(s, n, p) {
    var len;
    if (n == null) {
      n = 2;
    }
    if (p == null) {
      p = '0';
    }
    if (!(s && typeof s === 'string')) {
      return '';
    }
    len = n - s.length;
    if (len <= 0) {
      return s;
    }
    return ((function() {
      var j, ref1, results;
      results = [];
      for (j = 1, ref1 = len; 1 <= ref1 ? j <= ref1 : j >= ref1; 1 <= ref1 ? j++ : j--) {
        results.push(p);
      }
      return results;
    })()).join('') + s;
  },
  randomColorString: function(min, max) {
    if (min == null) {
      min = 0xff >> 1;
    }
    if (max == null) {
      max = 0xff;
    }
    return '#' + Util.padString(Util.randomInt(min, max).toString(16)) + Util.padString(Util.randomInt(min, max).toString(16)) + Util.padString(Util.randomInt(min, max).toString(16));
  },
  lerp: function(p0, p1, rate) {
    var i, j, len, ref1, results;
    if (rate <= 0) {
      return p0;
    }
    if (rate >= 1) {
      return p1;
    }
    if (!(p1 && p0 && (len = min(p0.length, p1.length)) > 0)) {
      return p1;
    }
    results = [];
    for (i = j = 0, ref1 = len; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
      results.push(trunc(((p1[i] - p0[i]) * rate + p0[i]) * 100) / 100);
    }
    return results;
  },
  lerpAll: function(points, rate) {
    var irate, j, len1, point, results;
    irate = 1 - rate;
    results = [];
    for (j = 0, len1 = points.length; j < len1; j++) {
      point = points[j];
      if (point.length > 1) {
        results.push(this.lerp(point[0], point[1], rate, irate));
      }
    }
    return results;
  }
};
