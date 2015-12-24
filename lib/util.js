var Util;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Util = {
  areSquareBoundsOverlapped: function(a, b) {
    var i, j, ref;
    if (!(Array.isArray(a) && Array.isArray(b))) {
      return;
    }
    for (i = j = 0, ref = a[0].length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (a[0][i] < b[0][i]) {
        if (b[0][i] - a[0][i] > a[1][i]) {
          return false;
        }
      } else {
        if (a[0][i] - b[0][i] > a[1][i]) {
          return false;
        }
      }
    }
    return true;
  },
  isInSquareBounds: function(point, bounds) {
    var delta, i, j, len, ref;
    if (!(Array.isArray(point) && Array.isArray(bounds) && bounds.length === 2)) {
      return;
    }
    len = Math.min(Math.min(bounds[0].length, bounds[1].length), point.length);
    for (i = j = 0, ref = len; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      delta = point[i] - bounds[0][i];
      if (delta < 0 || delta > bounds[1][i]) {
        return false;
      }
    }
    return true;
  },
  toroidalDelta: function(p0, p1, pLimit) {
    var adelta, delta, i, j, len, ref, results, sign;
    if (!(p0 && p1 && pLimit)) {
      return;
    }
    len = Math.min(Math.min(p0.length, p1.length), pLimit.length);
    if (len < 1) {
      return [];
    }
    results = [];
    for (i = j = 0, ref = len; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
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
    var j, ref, slot;
    if (!(arr && Array.isArray(arr))) {
      return;
    }
    for (slot = j = 0, ref = arr.length; 0 <= ref ? j <= ref : j >= ref; slot = 0 <= ref ? ++j : --j) {
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
    if (!(Array.isArray(arr) && arr.length && typeof f === 'function')) {
      return -1;
    }
    if ((function() {
      var j, ref, results;
      results = [];
      for (i = j = 0, ref = arr.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
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
    return Math.floor(Math.random() * (max - min) + min);
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
      var j, ref, results;
      results = [];
      for (j = 1, ref = len; 1 <= ref ? j <= ref : j >= ref; 1 <= ref ? j++ : j--) {
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
    var i, j, len, ref, results;
    if (rate <= 0) {
      return p0;
    }
    if (rate >= 1) {
      return p1;
    }
    if (!(p1 && p0 && (len = Math.min(p0.length, p1.length)) > 0)) {
      return p1;
    }
    results = [];
    for (i = j = 0, ref = len; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      results.push(Math.trunc(((p1[i] - p0[i]) * rate + p0[i]) * 100) / 100);
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
