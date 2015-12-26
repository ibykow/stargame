var Arrow, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Arrow = (function() {
  function Arrow(game, a, b, color, alpha, lineWidth, id) {
    this.game = game;
    this.a = a;
    this.b = b;
    this.color = color != null ? color : "#0f0";
    this.alpha = alpha != null ? alpha : 1;
    this.lineWidth = lineWidth != null ? lineWidth : 0.5;
    this.id = id;
    if (!(this.game && this.a && this.b)) {
      return;
    }
    this.magnitude = 0;
    this.prevMagnitude = 0;
  }

  Arrow.prototype.update = function() {
    var p;
    p = Util.toroidalDelta(this.a.view, this.b.view, this.game.toroidalLimit);
    p[2] = Math.atan2(p[0], p[1]);
    this.theta = Math.PI - p[2];
    this.magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1]);
    if (this.magnitude < this.game.canvas.halfHeight) {
      return this.viewAlpha = Math.min(this.alpha, this.magnitude / this.game.canvas.halfHeight);
    } else {
      return this.viewAlpha = this.alpha;
    }
  };

  Arrow.prototype.draw = function() {
    var bottom, c, side, top;
    top = (this.magnitude * this.game.canvas.halfHeight) / this.game.width + 30;
    side = top - 10;
    bottom = Math.min(side, 25);
    c = this.game.c;
    c.save();
    c.translate(this.a.view[0], this.a.view[1]);
    c.rotate(this.theta);
    c.globalAlpha = this.viewAlpha;
    c.strokeStyle = this.color;
    c.lineWidth = this.lineWidth;
    c.beginPath();
    c.moveTo(0, bottom);
    c.lineTo(3, side);
    c.lineTo(8, side);
    c.lineTo(0, top);
    c.lineTo(-8, side);
    c.lineTo(-3, side);
    c.closePath();
    c.stroke();
    return c.restore();
  };

  return Arrow;

})();
