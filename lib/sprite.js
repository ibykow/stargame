var Sprite, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  Sprite.interpolate = function(prevState, nextState, rate) {
    var o, o0, o1, ref, ref1, ref2, vx, vx0, vx1, vy, vy0, vy1, x, x0, x1, y, y0, y1;
    ref = [prevState.velocity[0], nextState.velocity[0], prevState.velocity[1], nextState.velocity[1]], vx0 = ref[0], vx1 = ref[1], vy0 = ref[2], vy1 = ref[3];
    vx = (vx1 - vx0) * rate + vx0;
    vy = (vy1 - vy0) * (vx - vx0) / (vx1 - vx0) + vy0;
    ref1 = [prevState.position[0], nextState.position[0], prevState.position[1], nextState.position[1]], x0 = ref1[0], x1 = ref1[1], y0 = ref1[2], y1 = ref1[3];
    x = (x1 - x0) * rate + x0;
    y = (y1 - y0) * (x - x0) / (x1 - x0) + y0;
    ref2 = [prevState.position[2], nextState.position[2]], o0 = ref2[0], o1 = ref2[1];
    o = (o1 - o0) * rate + o0;
    return {
      velocity: [vx, vy],
      position: [x, y, o]
    };
  };

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

  Sprite.prototype.setState = function(state) {
    var ref, ref1, ref2, ref3, ref4;
    this.position = (ref = state.position) != null ? ref : this.position;
    this.velocity = (ref1 = state.velocity) != null ? ref1 : this.velocity;
    this.width = (ref2 = state.width) != null ? ref2 : this.width;
    this.height = (ref3 = state.height) != null ? ref3 : this.height;
    return this.color = (ref4 = state.color) != null ? ref4 : this.color;
  };

  Sprite.prototype.draw = function() {
    this.game.c.fillStyle = this.color;
    return this.game.c.fillRect(this.position[0] - this.width / 2, this.position[1] - this.height / 2, this.width, this.height);
  };

  return Sprite;

})();
