var Sprite;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  function Sprite(game, position1) {
    this.game = game;
    this.position = position1;
    if (!this.game) {
      return null;
    }
    if (this.position == null) {
      this.position = this.game.randomPosition();
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
    for (i = j = 0, ref = position.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      results.push(this.position[i] += this.velocity[i]);
    }
    return results;
  };

  Sprite.prototype.update = function() {
    this.updateVelocity();
    return this.updatePosition();
  };

  return Sprite;

})();
