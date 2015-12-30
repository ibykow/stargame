var Sprite, Util, abs, isarr, ref, round, sqrt, trunc;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

ref = [Math.abs, Array.isArray, Math.sqrt, Math.round, Math.trunc], abs = ref[0], isarr = ref[1], sqrt = ref[2], round = ref[3], trunc = ref[4];

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
    this.velocity = [0, 0];
    this.magnitude = 0;
    this.halfWidth = this.width / 2;
    this.halfHeight = this.height / 2;
    this.children = {};
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
    this.flags = {
      isVisible: true,
      isRigid: true,
      isDeleted: false
    };
    this.updateView();
  }

  Sprite.prototype.adopt = function(child, name) {
    var ref1;
    if (!child) {
      return;
    }
    if (name == null) {
      name = ((ref1 = child.constructor) != null ? ref1.name : void 0) || 'annie';
    }
    this.children[name] = child;
    return child.parent = this;
  };

  Sprite.prototype.clearFlags = function() {
    var k, results;
    results = [];
    for (k in this.flags) {
      results.push(this.flags[k] = false);
    }
    return results;
  };

  Sprite.prototype.handleBulletImpact = function(b) {
    if (!(this.flags.isRigid && (b != null ? b.damage : void 0))) {
      return;
    }
    return b.life = 0;
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
    this.velocity[0] = trunc(this.velocity[0] * this.game.frictionRate * 100) / 100;
    this.velocity[1] = trunc(this.velocity[1] * this.game.frictionRate * 100) / 100;
    return this.magnitude = sqrt(this.velocity.reduce((function(sum, v) {
      return sum + v * v;
    }), 0));
  };

  Sprite.prototype.updatePosition = function() {
    var x, y;
    x = round((this.position[0] + this.velocity[0] + this.game.width) % this.game.width);
    y = round((this.position[1] + this.velocity[1] + this.game.height) % this.game.height);
    this.position[0] = x;
    return this.position[1] = y;
  };

  Sprite.prototype.updateChildren = function() {
    var child, ref1, results, type;
    ref1 = this.children;
    results = [];
    for (type in ref1) {
      child = ref1[type];
      results.push(child.update());
    }
    return results;
  };

  Sprite.prototype.updateAlt = function() {};

  Sprite.prototype.update = function() {
    this.updateVelocity();
    this.updatePosition();
    this.updateView();
    return this.updateChildren();
  };

  Sprite.prototype.getState = function() {
    var child, childStates, ref1, type;
    childStates = {};
    ref1 = this.children;
    for (type in ref1) {
      child = ref1[type];
      childStates[type] = child.getState();
    }
    return {
      position: this.position.slice(),
      velocity: this.velocity.slice(),
      width: this.width,
      height: this.height,
      color: this.color,
      flags: this.flags,
      children: childStates
    };
  };

  Sprite.prototype.setState = function(state) {
    this.position = state.position;
    this.velocity = state.velocity;
    this.width = state.width;
    this.height = state.height;
    this.color = state.color;
    this.flags = state.flags;
    return this.children = state.children;
  };

  Sprite.prototype.draw = function() {
    var child, ref1, results, type;
    if (!this.flags.isVisible) {
      return;
    }
    this.game.c.fillStyle = this.color;
    this.game.c.fillRect(this.view[0] - this.halfWidth, this.view[1] - this.halfHeight, this.width, this.height);
    ref1 = this.children;
    results = [];
    for (type in ref1) {
      child = ref1[type];
      results.push(child.draw(this.view));
    }
    return results;
  };

  return Sprite;

})();
