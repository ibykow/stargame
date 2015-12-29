var Bullet, Config, Ship, Sprite, abs, accelerationRate, brakeRate, cos, floor, max, min, ref, ref1, sin, trunc, turnRate,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Sprite = require('./sprite');
  Bullet = require('./bullet');
}

ref = [Math.abs, Math.floor, Math.min, Math.max, Math.trunc, Math.cos, Math.sin], abs = ref[0], floor = ref[1], min = ref[2], max = ref[3], trunc = ref[4], cos = ref[5], sin = ref[6];

ref1 = [Config.common.ship.rates.acceleration, Config.common.ship.rates.brake, Config.common.ship.rates.turn], accelerationRate = ref1[0], brakeRate = ref1[1], turnRate = ref1[2];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Ship = (function(superClass) {
  extend(Ship, superClass);

  Ship.glideBrake = function() {
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    this.velocity[0] *= brakeRate;
    return this.velocity[1] *= brakeRate;
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
    this.brakePower = 550;
    this.accFactor = accelerationRate;
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
    return this.position[2] -= turnRate;
  };

  Ship.prototype.right = function() {
    return this.position[2] += turnRate;
  };

  Ship.prototype.brake = function() {
    var rate;
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    rate = min(this.magnitude * this.magnitude / this.brakePower, brakeRate);
    this.velocity[0] *= rate;
    return this.velocity[1] *= rate;
  };

  Ship.prototype.fire = function() {
    return this.game.bullets.push(new Bullet(this)) - 1;
  };

  Ship.prototype.handleBulletCollisions = function() {
    var b, i, len, ref2, results;
    this.updateBulletCollisions();
    ref2 = this.bulletCollisions;
    results = [];
    for (i = 0, len = ref2.length; i < len; i++) {
      b = ref2[i];
      results.push(this.health--);
    }
    return results;
  };

  Ship.prototype.getState = function() {
    var s;
    s = Ship.__super__.getState.call(this);
    s.health = this.health;
    return s;
  };

  Ship.prototype.setState = function(s) {
    Ship.__super__.setState.call(this, s);
    return this.health = s.health, s;
  };

  Ship.prototype.update = function() {
    Ship.__super__.update.call(this);
    return this.handleBulletCollisions();
  };

  Ship.prototype.draw = function() {
    return Ship.draw(this.player.game.c, this.view, this.color);
  };

  Ship.prototype.updateViewMaster = function() {
    var halfh, halfw, r, ref2, vx, vy, x, y;
    ref2 = [this.position[0], this.position[1], this.position[2], this.velocity[0], this.velocity[1], this.game.canvas.halfWidth, this.game.canvas.halfHeight], x = ref2[0], y = ref2[1], r = ref2[2], vx = ref2[3], vy = ref2[4], halfw = ref2[5], halfh = ref2[6];
    this.view = [halfw + vx, halfh + vy, r];
    this.game.viewOffset = [x - halfw, y - halfh];
    return this.flags.isVisible = true;
  };

  return Ship;

})(Sprite);
