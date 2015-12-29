var Sprite, Util, abs, isarr, ref, sqrt;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

ref = [Math.abs, Array.isArray, Math.sqrt], abs = ref[0], isarr = ref[1], sqrt = ref[2];

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  Sprite.prototype.flags = {
    isVisible: false,
    isRigid: true
  };

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
    this.velocity = [0, 0];
    this.magnitude = 0;
    this.halfWidth = this.width / 2;
    this.halfHeight = this.height / 2;
    this.bulletCollisions = [];
    this.mouse = {
      hovering: false,
      enter: function() {
        return console.log('Planning on staying long?');
      },
      leave: function() {
        return console.log("Please don't leave me!");
      },
      click: function() {
        return console.log('You clicked me!');
      }
    };
    this.updateView();
  }

  Sprite.prototype.clearFlags = function() {
    var j, k, len, ref1, results;
    ref1 = this.flags;
    results = [];
    for (j = 0, len = ref1.length; j < len; j++) {
      k = ref1[j];
      results.push(this.flags[k] = false);
    }
    return results;
  };

  Sprite.prototype.detectCollisions = function(sprites, maxIndex) {
    if (sprites == null) {
      sprites = this.game.visibleSprites;
    }
    if (!(isarr(sprites) && this.flags.isRigid)) {
      return [];
    }
    return sprites.filter((function(_this) {
      return function(sprite, i) {
        return sprite.flags.isRigid && _this.intersects(sprite);
      };
    })(this));
  };

  Sprite.prototype.intersects = function(sprite) {
    var delta;
    if (this === sprite || !(sprite != null ? sprite.position : void 0)) {
      return false;
    }
    delta = Util.toroidalDelta(this.position, sprite.position, this.game.toroidalLimit);
    return (abs(delta[0]) <= this.halfWidth + sprite.halfWidth) && (abs(delta[1]) <= this.halfHeight + sprite.halfHeight);
  };

  Sprite.prototype.getBoundsFor = function(type) {
    if (type == null) {
      type = 'view';
    }
    return [[this[type][0] - this.halfWidth, this[type][1] - this.halfHeight], [this.width, this.height]];
  };

  Sprite.prototype.getBounds = function() {
    return this.getBoundsFor('position');
  };

  Sprite.prototype.getViewBounds = function() {
    return this.getBoundsFor('view');
  };

  Sprite.prototype.isInView = function() {
    var ch, cw, h, w;
    w = this.halfWidth;
    h = this.halfHeight;
    cw = this.game.canvas.width;
    ch = this.game.canvas.height;
    return (this.game.c != null) && (this.view[0] >= -w) && (this.view[1] >= -h) && (this.view[0] <= cw + w) && (this.view[1] <= ch + h);
  };

  Sprite.prototype.updateView = function() {
    this.view = Util.toroidalDelta(this.position, this.game.viewOffset, this.game.toroidalLimit);
    this.view[2] = this.position[2];
    if (this.flags.isVisible = this.isInView()) {
      return this.game.visibleSprites.push(this);
    }
  };

  Sprite.prototype.updateVelocity = function() {
    this.velocity[0] = Math.trunc(this.velocity[0] * this.game.frictionRate * 100) / 100;
    this.velocity[1] = Math.trunc(this.velocity[1] * this.game.frictionRate * 100) / 100;
    return this.magnitude = sqrt(this.velocity.reduce((function(sum, v) {
      return sum + v * v;
    }), 0));
  };

  Sprite.prototype.updatePosition = function() {
    var x, y;
    x = Math.round((this.position[0] + this.velocity[0] + this.game.width) % this.game.width);
    y = Math.round((this.position[1] + this.velocity[1] + this.game.height) % this.game.height);
    this.position[0] = x;
    return this.position[1] = y;
  };

  Sprite.prototype.updateBulletCollisions = function() {
    return this.bulletCollisions = this.detectCollisions(this.game.bullets);
  };

  Sprite.prototype.update = function() {
    this.clearFlags();
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
    var ref1, ref2, ref3, ref4, ref5;
    this.position = (ref1 = state.position) != null ? ref1 : this.position;
    this.velocity = (ref2 = state.velocity) != null ? ref2 : this.velocity;
    this.width = (ref3 = state.width) != null ? ref3 : this.width;
    this.height = (ref4 = state.height) != null ? ref4 : this.height;
    return this.color = (ref5 = state.color) != null ? ref5 : this.color;
  };

  Sprite.prototype.draw = function() {
    if (!this.flags.isVisible) {
      return;
    }
    this.game.c.fillStyle = this.color;
    return this.game.c.fillRect(this.view[0] - this.halfWidth, this.view[1] - this.halfHeight, this.width, this.height);
  };

  return Sprite;

})();
