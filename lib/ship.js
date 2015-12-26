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
    Ship.__super__.constructor.call(this, this.player.game, this.position, 20, 20);
    this.gear = 0;
    this.flags.isBraking = false;
    this.topSpeed = 100;
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
    if (!this.magnitude) {
      return;
    }
    this.isBraking = true;
    this.velocity[0] *= Ship.RATES.BRAKE;
    return this.velocity[1] *= Ship.RATES.BRAKE;
  };

  Ship.prototype.fire = function() {
    console.log('firing');
    return this.game.sprites.push(new Bullet(this));
  };

  Ship.prototype.update = function() {
    Ship.__super__.update.call(this);
    return this.updateCollisions();
  };

  Ship.prototype.draw = function() {
    return Ship.draw(this.player.game.c, this.view, this.color);
  };

  Ship.drawMaster = function() {
    return Ship.draw(this.player.game.c, [this.game.canvas.halfWidth + this.velocity[0], this.game.canvas.halfHeight + this.velocity[1], this.position[2]], this.color);
  };

  Ship.updateViewMaster = function() {
    this.view = [this.game.canvas.halfWidth + this.velocity[0], this.game.canvas.halfHeight + this.velocity[1], this.position[2]];
    this.game.viewOffset = [this.position[0] - this.game.canvas.halfWidth, this.position[1] - this.game.canvas.halfHeight];
    return this.flags.isVisible = true;
  };

  return Ship;

})(Sprite);
