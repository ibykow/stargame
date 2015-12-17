var Sprite, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  function Sprite(game, position, width, height, color) {
    this.game = game;
    this.position = position;
    this.width = width != null ? width : 10;
    this.height = height != null ? height : 10;
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
    var i, j, ref, results;
    results = [];
    for (i = j = 0, ref = this.position.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      results.push(this.position[i] += this.velocity[i]);
    }
    return results;
  };

  Sprite.prototype.update = function() {
    this.updateVelocity();
    return this.updatePosition();
  };

  Sprite.prototype.draw = function() {
    this.game.c.fillStyle = this.color;
    return this.game.c.fillRect(this.position[0] - this.width / 2, this.position[1] - this.height / 2, this.width, this.height);
  };

  return Sprite;

})();
