var Bullet, Config, Ship, Sprite, abs, cos, floor, max, min, ref, shipRates, sin, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Sprite = require('./sprite');
  Bullet = require('./bullet');
}

ref = [Math.abs, Math.floor, Math.min, Math.max, Math.trunc, Math.cos, Math.sin], abs = ref[0], floor = ref[1], min = ref[2], max = ref[3], trunc = ref[4], cos = ref[5], sin = ref[6];

shipRates = Config.common.ship.rates;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Ship = (function(superClass) {
  extend(Ship, superClass);

  Ship.glideBrake = function() {
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    this.velocity[0] *= shipRate.brake;
    return this.velocity[1] *= shipRates.brake;
  };

  Ship.draw = function(c, position, color) {
    if (!(c && position && color)) {
      return;
    }
    c.save();
    c.fillStyle = color;
    c.translate.apply(c, position);
    c.rotate(position[2]);
    c.globalAlpha = 1;
    c.beginPath();
    c.moveTo(10, 0);
    c.lineTo(-10, 5);
    c.lineTo(-10, -5);
    c.closePath();
    c.fill();
    return c.restore();
  };

  function Ship(player, position1) {
    this.player = player;
    this.position = position1;
    if (!this.player) {
      return null;
    }
    Ship.__super__.constructor.call(this, this.player.game, this.position, 10, 10);
    this.health = 100;
    this.gear = 0;
    this.flags.isBraking = false;
    this.lastFireInputSequence = 0;
    this.fireRate = shipRates.fire;
    this.brakePower = 550;
    this.accFactor = shipRates.acceleration;
  }

  Ship.prototype.forward = function() {
    this.velocity[0] += cos(this.position[2]) * this.accFactor;
    return this.velocity[1] += sin(this.position[2]) * this.accFactor;
  };

  Ship.prototype.reverse = function() {
    this.velocity[0] -= cos(this.position[2]);
    return this.velocity[1] -= sin(this.position[2]);
  };

  Ship.prototype.left = function() {
    return this.position[2] -= shipRates.turn;
  };

  Ship.prototype.right = function() {
    return this.position[2] += shipRates.turn;
  };

  Ship.prototype.brake = function() {
    var rate;
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    rate = min(this.magnitude * this.magnitude / this.brakePower, shipRates.brake);
    this.velocity[0] *= rate;
    return this.velocity[1] *= rate;
  };

  Ship.prototype.fire = function() {
    if (!(this.lastFireInputSequence < this.player.inputSequence - this.fireRate)) {
      return;
    }
    this.lastFireInputSequence = this.player.inputSequence;
    return this.game.insertBullet(new Bullet(this));
  };

  Ship.prototype.handleBulletCollisions = function() {
    var b, i, len, ref1, results;
    this.updateBulletCollisions();
    ref1 = this.bulletCollisions;
    results = [];
    for (i = 0, len = ref1.length; i < len; i++) {
      b = ref1[i];
      results.push(this.health -= b.damage);
    }
    return results;
  };

  Ship.prototype.getState = function() {
    var s;
    s = Ship.__super__.getState.call(this);
    s.health = this.health;
    s.lastFireInputSequence = this.lastFireInputSequence;
    s.fireRate = this.fireRate;
    return s;
  };

  Ship.prototype.setState = function(s) {
    Ship.__super__.setState.call(this, s);
    return this.health = s.health, this.lastFireInputSequence = s.lastFireInputSequence, this.fireRate = s.fireRate, s;
  };

  Ship.prototype.update = function() {
    Ship.__super__.update.call(this);
    return this.handleBulletCollisions();
  };

  Ship.prototype.draw = function() {
    return Ship.draw(this.player.game.c, this.view, this.color);
  };

  Ship.prototype.updateViewMaster = function() {
    var halfh, halfw, r, ref1, vx, vy, x, y;
    ref1 = [this.position[0], this.position[1], this.position[2], this.velocity[0], this.velocity[1], this.game.canvas.halfWidth, this.game.canvas.halfHeight], x = ref1[0], y = ref1[1], r = ref1[2], vx = ref1[3], vy = ref1[4], halfw = ref1[5], halfh = ref1[6];
    this.view = [halfw + vx, halfh + vy, r];
    this.game.viewOffset = [x - halfw, y - halfh];
    return this.flags.isVisible = true;
  };

  return Ship;

})(Sprite);
