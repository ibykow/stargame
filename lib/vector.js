var Util, Vector;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Vector = (function() {
  function Vector(game, a, b, color, alpha, lineWidth, id) {
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
  }

  Vector.prototype.update = function() {
    var limit, p;
    limit = [this.game.width, this.game.height];
    p = this.position = Util.toroidalDelta(this.a.view, this.b.view, limit);
    this.magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1]);
    this.position[2] = Math.atan2(p[0], p[1]);
    this.view = [p[0], p[1], Math.PI - p[2]];
    if (this.magnitude < this.game.canvas.halfHeight) {
      return this.view[3] = Math.min(this.alpha, this.magnitude / this.game.canvas.halfHeight);
    } else {
      return this.view[3] = this.alpha;
    }
  };

  Vector.prototype.draw = function() {
    var bottom, c, side, top;
    top = (this.magnitude * this.game.canvas.halfHeight) / this.game.width + 30;
    side = top - 10;
    bottom = Math.min(side, 25);
    c = this.game.c;
    c.save();
    c.translate(this.a.view[0], this.a.view[1]);
    c.rotate(this.view[2]);
    c.globalAlpha = this.view[3];
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

  return Vector;

})();
