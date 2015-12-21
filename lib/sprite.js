var Sprite, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  Sprite.interpolate = function(prevState, nextState, rate) {
    return {
      velocity: Util.lerp(prevState.velocity, nextState.velocity, rate),
      position: Util.lerp(prevState.position, nextState.position, rate)
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
    this.velocity = [0, 0];
    this.visible = false;
    this.halfWidth = this.width / 2;
    this.halfHeight = this.height / 2;
    this.updateView();
  }

  Sprite.prototype.isInView = function() {
    return (this.game.c != null) && (this.view[0] >= -this.halfWidth) && (this.view[1] >= -this.halfHeight) && (this.view[0] <= this.game.canvas.width + this.halfWidth) && (this.view[1] <= this.game.canvas.height + this.halfHeight);
  };

  Sprite.prototype.updateView = function() {
    var limit;
    if (this.game.c == null) {
      return;
    }
    limit = [this.game.width, this.game.height];
    this.view = Util.toroidalDelta(this.position, this.game.viewOffset, limit);
    this.view[2] = this.position[2];
    return this.visible = this.isInView();
  };

  Sprite.prototype.updateVelocity = function() {
    this.velocity[0] = Math.trunc(this.velocity[0] * this.game.frictionRate * 100) / 100;
    return this.velocity[1] = Math.trunc(this.velocity[1] * this.game.frictionRate * 100) / 100;
  };

  Sprite.prototype.updatePosition = function() {
    this.position[0] = (this.position[0] + this.velocity[0] + this.game.width) % this.game.width;
    return this.position[1] = (this.position[1] + this.velocity[1] + this.game.height) % this.game.height;
  };

  Sprite.prototype.update = function() {
    this.updateVelocity();
    this.updatePosition();
    return this.updateView();
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
    if (!this.visible) {
      return;
    }
    this.game.c.fillStyle = this.color;
    return this.game.c.fillRect(this.view[0] - this.width / 2, this.view[1] - this.height / 2, this.width, this.height);
  };

  return Sprite;

})();
