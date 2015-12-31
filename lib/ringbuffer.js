var RingBuffer, Util, min;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

min = [Math.min][0];

(typeof module !== "undefined" && module !== null ? module : {}).exports = RingBuffer = (function() {
  RingBuffer.DEFAULT_MAX = 50;

  function RingBuffer(max) {
    this.max = max != null ? max : RingBuffer.DEFAULT_MAX;
    if (this.max < 2) {
      return;
    }
    this.data = new Array(this.max);
    this.reset();
  }

  RingBuffer.prototype.reset = function() {
    this.head = 0;
    this.tail = 0;
    return this.full = false;
  };

  RingBuffer.prototype.purge = function(f) {
    var o, results;
    if (typeof f === 'function') {
      results = [];
      while ((o = this.peek()) && (f(o) === true)) {
        results.push(this.remove());
      }
      return results;
    } else {
      return this.reset();
    }
  };

  RingBuffer.prototype.find = function(f) {
    var o;
    if (typeof f !== 'function') {
      return;
    }
    while (o = this.peek()) {
      if (f(o)) {
        return o;
      }
    }
    return null;
  };

  RingBuffer.prototype.isEmpty = function() {
    return this.head === this.tail && !this.full;
  };

  RingBuffer.prototype.toArray = function() {
    if (this.isEmpty()) {
      return [];
    }
    if (this.head > this.tail) {
      return this.data.slice(this.tail, this.head);
    } else {
      return this.data.slice(this.tail, this.max).concat(this.data.slice(0, this.head));
    }
  };

  RingBuffer.prototype.insert = function(o) {
    if (!o) {
      return;
    }
    if (this.full) {
      this.tail = (this.tail + 1) % this.max;
    }
    this.data[this.head] = o;
    this.head = (this.head + 1) % this.max;
    return this.full = this.head === this.tail;
  };

  RingBuffer.prototype.remove = function() {
    var item;
    if (this.isEmpty()) {
      return null;
    }
    item = this.data[this.tail];
    this.tail = (this.tail + 1) % this.max;
    this.full = false;
    return item;
  };

  RingBuffer.prototype.peek = function() {
    if (this.isEmpty()) {
      return null;
    } else {
      return this.data[this.tail];
    }
  };

  RingBuffer.prototype.map = function(f) {
    var i, results, ret;
    if (this.isEmpty() || !this.isSane()) {
      return [];
    }
    i = this.tail;
    results = [];
    while (!(i === this.head)) {
      ret = f(this.data[i], i, this);
      i = (i + 1) % this.max;
      results.push(ret);
    }
    return results;
  };

  RingBuffer.prototype.isSane = function() {
    return (this.tail >= 0) && (this.tail < this.max) && (this.head >= 0) && (this.head < this.max) && ((this.full && (this.tail === this.head)) || true);
  };

  return RingBuffer;

})();
