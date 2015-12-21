var Util, Vector;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Vector = (function() {
  function Vector(game, a, b, color, alpha, id) {
    this.game = game;
    this.a = a;
    this.b = b;
    this.color = color;
    this.alpha = alpha;
    this.id = id;
    if (!(this.game && this.a && this.b)) {
      return;
    }
    if (this.color == null) {
      this.color = "#0f0";
    }
    console.log('vector color', this.color);
    this.update();
    if (this.alpha == null) {
      this.alpha = 1;
    }
  }

  Vector.prototype.update = function() {
    var limit, p;
    limit = [this.game.width, this.game.height];
    p = this.position = Util.toroidalDelta(this.a.view, this.b.view, limit);
    this.magnitude = Math.sqrt(p[0] * p[0] + p[1] * p[1]);
    if (this.magnitude < this.game.canvas.halfHeight) {
      this.viewAlpha = Math.min(this.alpha, this.magnitude / this.game.canvas.halfHeight);
    } else {
      this.viewAlpha = this.alpha;
    }
    this.position[2] = Math.atan2(p[0], p[1]);
    return this.view = [p[0], p[1], Math.PI - p[2]];
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
    c.globalAlpha = this.viewAlpha;
    c.strokeStyle = this.color;
    c.lineWidth = 0.5;
    c.beginPath();
    c.moveTo(0, bottom);
    c.lineTo(3, side);
    c.lineTo(8, side);
    c.lineTo(0, top);
    c.lineTo(-8, side);
    c.lineTo(-3, side);
    c.moveTo(0, bottom);
    c.stroke();
    c.closePath();
    return c.restore();
  };

  return Vector;

})();
