var Ship, Sprite,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Ship = (function(superClass) {
  extend(Ship, superClass);

  Ship.BRAKE_RATE = 0.8;

  function Ship(player) {
    this.player = player;
    if (!this.player) {
      return null;
    }
    Ship.__super__.constructor.call(this, this.player.game);
    this.gear = 0;
    this.brake = false;
  }

  Ship.prototype.updateVelocity = function() {
    if (this.brake) {
      this.brake = false;
      this.velocity[0] *= Ship.BRAKE_RATE;
      this.velocity[1] *= Ship.BRAKE_RATE;
    } else if (this.gear) {
      this.velocity[0] += this.gear * Math.cos(this.position[2]);
      this.velocity[1] += this.gear * Math.sin(this.position[2]);
    }
    return Ship.__super__.updateVelocity.call(this);
  };

  return Ship;

})(Sprite);
