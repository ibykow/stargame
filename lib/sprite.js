var Sprite, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  function Sprite(game, width, height, position, color) {
    this.game = game;
    this.width = width != null ? width : 10;
    this.height = height != null ? height : 10;
    this.position = position;
    this.color = color;
    if (!this.game) {
      return null;
    }
    if (this.position == null) {
      this.position = this.game.randomPosition();
    }
    if (this.color == null) {
      this.color = Util.randomColorString();
    }
    this.velocity = [0, 0, 0];
  }

  Sprite.prototype.updateVelocity = function() {
    this.velocity[0] *= this.game.frictionRate;
    return this.velocity[1] *= this.game.frictionRate;
  };

  Sprite.prototype.updatePosition = function() {
    var i, j, ref;
    for (i = j = 0, ref = this.position.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      this.position[i] += this.velocity[i];
    }
    this.position[0] = (this.position[0] + this.game.width) % this.game.width;
    return this.position[1] = (this.position[1] + this.game.height) % this.game.height;
  };

  Sprite.prototype.update = function() {
    this.updateVelocity();
    return this.updatePosition();
  };

  Sprite.prototype.getState = function() {
    return {
      position: this.position,
      velocity: this.velocity,
      width: this.width,
      height: this.height,
      color: this.color
    };
  };

  Sprite.prototype.draw = function() {
    this.game.c.fillStyle = this.color;
    return this.game.c.fillRect(this.position[0] - this.width / 2, this.position[1] - this.height / 2, this.width, this.height);
  };

  return Sprite;

})();
