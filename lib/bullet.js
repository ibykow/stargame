var Bullet, Sprite, Util,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Sprite = require('./sprite');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Bullet = (function(superClass) {
  extend(Bullet, superClass);

  Bullet.SPEED = 10;

  function Bullet(gun) {
    this.gun = gun;
    if (!this.gun) {
      return;
    }
    Bullet.__super__.constructor.call(this, this.gun.game, this.gun.position.slice(), 2, 2, "#ffd");
    this.velocity = [Math.cos(this.position[2]) * Bullet.SPEED, Math.sin(this.position[2]) * Bullet.SPEED];
    this.life = 60 * 16 * 3;
  }

  Bullet.prototype.updateVelocity = function() {};

  Bullet.prototype.update = function() {
    Bullet.__super__.update.call(this);
    return this.life--;
  };

  return Bullet;

})(Sprite);
