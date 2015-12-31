var Config, RingBuffer, Util, min;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
}

min = [Math.min][0];

(typeof module !== "undefined" && module !== null ? module : {}).exports = RingBuffer = (function() {
  function RingBuffer(max) {
    this.max = max != null ? max : Config.common.ringbuffer.max;
    if (this.max < 2) {
      return;
    }
    this.data = new Array(this.max);
    this.reset();
  }

  RingBuffer.prototype.reset = function() {
    this.head = 0;
    this.tail = 0;
    this.full = false;
    return this.length = 0;
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
    return this.length === 0;
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
    this.full = this.head === this.tail;
    return this.length++;
  };

  RingBuffer.prototype.remove = function() {
    var item;
    if (this.isEmpty()) {
      return null;
    }
    item = this.data[this.tail];
    this.tail = (this.tail + 1) % this.max;
    this.full = false;
    this.length--;
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
    var i, index, results, ret;
    if (this.isEmpty() || !this.isSane()) {
      return [];
    }
    i = this.tail;
    index = 0;
    results = [];
    while (!(index === this.length)) {
      ret = f(this.data[i], index, this);
      i = (i + 1) % this.max;
      index++;
      results.push(ret);
    }
    return results;
  };

  RingBuffer.prototype.isSane = function() {
    return (this.tail >= 0) && (this.tail < this.max) && (this.head >= 0) && (this.head < this.max) && ((this.full && (this.tail === this.head)) || true);
  };

  return RingBuffer;

})();
