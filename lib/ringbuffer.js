var RingBuffer, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = RingBuffer = (function() {
  RingBuffer.DEFAULT_MAX = 50;

  function RingBuffer(max) {
    this.max = max != null ? max : RingBuffer.DEFAULT_MAX;
    if (this.max < 2) {
      return;
    }
    this.data = new Array(this.max);
    this.head = 0;
    this.tail = 0;
    this.full = false;
  }

  RingBuffer.prototype.toArray = function() {
    if (this.head === this.tail && !this.full) {
      return [];
    }
    if (this.head > this.tail) {
      return this.data.slice(this.tail, this.head);
    } else {
      return this.data.slice(this.tail, this.max).concat(this.data.slice(0, this.head));
    }
  };

  RingBuffer.prototype.insert = function(o) {
    if (this.full) {
      this.tail = (this.tail + 1) % this.max;
    }
    this.data[this.head] = o;
    this.head = (this.head + 1) % this.max;
    return this.full = this.head === this.tail;
  };

  RingBuffer.prototype.remove = function() {
    var item;
    if (this.head === this.tail && !this.full) {
      return null;
    }
    item = this.data[this.tail];
    this.tail = (this.tail + 1) % this.max;
    this.full = false;
    return item;
  };

  RingBuffer.prototype.peek = function() {
    if (this.head === this.tail && !this.full) {
      return null;
    } else {
      return this.data[this.tail];
    }
  };

  return RingBuffer;

})();
