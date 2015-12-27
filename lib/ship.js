var Bullet, Ship, Sprite, abs, cos, floor, max, min, ref, sin, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
  Bullet = require('./bullet');
}

ref = [Math.abs, Math.floor, Math.min, Math.max, Math.trunc, Math.cos, Math.sin], abs = ref[0], floor = ref[1], min = ref[2], max = ref[3], trunc = ref[4], cos = ref[5], sin = ref[6];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Ship = (function(superClass) {
  extend(Ship, superClass);

  Ship.RATES = {
    ACC: 2,
    BRAKE: 0.96,
    TURN: 0.06
  };

  Ship.glideBrake = function() {
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    this.velocity[0] *= Ship.RATES.BRAKE;
    return this.velocity[1] *= Ship.RATES.BRAKE;
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
    this.gear = 0;
    this.flags.isBraking = false;
    this.brakePower = 550;
    this.accFactor = Ship.RATES.ACC;
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
    return this.position[2] -= Ship.RATES.TURN;
  };

  Ship.prototype.right = function() {
    return this.position[2] += Ship.RATES.TURN;
  };

  Ship.prototype.brake = function() {
    var rate;
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    rate = min(this.magnitude * this.magnitude / this.brakePower, Ship.RATES.BRAKE);
    this.velocity[0] *= rate;
    return this.velocity[1] *= rate;
  };

  Ship.prototype.fire = function() {
    return this.game.bullets.push(new Bullet(this));
  };

  Ship.prototype.handleBulletCollisions = function() {
    var b, i, len, ref1, results;
    this.updateBulletCollisions();
    ref1 = this.bulletCollisions;
    results = [];
    for (i = 0, len = ref1.length; i < len; i++) {
      b = ref1[i];
      results.push(console.log('player', b.gun.player.id, 'hit player', this.player.id));
    }
    return results;
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
