var Bullet, Sprite, Util, ceil, cos, ref, sin,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Sprite = require('./sprite');
}

ref = [Math.ceil, Math.cos, Math.sin], ceil = ref[0], cos = ref[1], sin = ref[2];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Bullet = (function(superClass) {
  extend(Bullet, superClass);

  Bullet.SPEED = 10;

  function Bullet(gun) {
    var vx, vy, xdir, xnorm, ydir, ynorm;
    this.gun = gun;
    if (!this.gun) {
      return;
    }
    Bullet.__super__.constructor.call(this, this.gun.game, this.gun.position.slice(), 2, 2, "#ffd");
    vx = this.gun.velocity[0];
    vy = this.gun.velocity[1];
    xdir = cos(this.position[2]);
    ydir = sin(this.position[2]);
    xnorm = ceil(xdir);
    ynorm = ceil(ydir);
    this.velocity = [xdir * Bullet.SPEED, ydir * Bullet.SPEED];
    this.position[0] += xdir * (this.gun.width + 2);
    this.position[1] += ydir * (this.gun.height + 2);
    this.life = 60 * 1;
    this.update();
  }

  Bullet.prototype.updateVelocity = function() {};

  Bullet.prototype.update = function() {
    Bullet.__super__.update.call(this);
    return this.life--;
  };

  return Bullet;

})(Sprite);
