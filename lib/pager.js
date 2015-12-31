var Config, Pager, RingBuffer, Util, cfg, min;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
  RingBuffer = require('./ringbuffer');
}

cfg = Config.client.pager;

min = [Math.min][0];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Pager = (function() {
  function Pager(game, maxlines) {
    this.game = game;
    if (maxlines == null) {
      maxlines = cfg.maxlines;
    }
    if (!this.game) {
      return;
    }
    this.buffer = new RingBuffer(maxlines);
  }

  Pager.prototype.page = function(message) {
    return this.buffer.insert({
      message: message,
      ttl: cfg.ttl
    });
  };

  Pager.prototype.draw = function() {
    this.buffer.purge(function(m) {
      return m.ttl < 1;
    });
    return this.buffer.map((function(_this) {
      return function(m, i, buf) {
        var yoffset;
        yoffset = _this.game.canvas.height - cfg.yoffset * (buf.length - i);
        _this.game.c.fillStyle = cfg.color;
        _this.game.c.font = cfg.font;
        _this.game.c.globalAlpha = min(m.ttl / cfg.fade, 1);
        _this.game.c.fillText(m.message, cfg.xoffset, yoffset);
        return m.ttl--;
      };
    })(this));
  };

  return Pager;

})();
