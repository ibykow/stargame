var Ship, Sprite,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Ship = (function(superClass) {
  extend(Ship, superClass);

  Ship.BRAKE_RATE = 0.8;

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
    this.gear = 0;
    this.width = 20;
    this.height = 20;
    this.brake = false;
    Ship.__super__.constructor.call(this, this.player.game, this.position);
  }

  Ship.prototype.draw = function() {
    return Ship.draw(this.player.game.c, this.view, this.color);
  };

  Ship.prototype.updateViewMaster = function() {
    this.view = [this.game.canvas.halfWidth + this.velocity[0], this.game.canvas.halfHeight + this.velocity[1], this.position[2]];
    this.game.viewOffset = [this.position[0] - this.game.canvas.halfWidth, this.position[1] - this.game.canvas.halfHeight];
    return this.visible = true;
  };

  return Ship;

})(Sprite);
