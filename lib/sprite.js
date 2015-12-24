var Sprite, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Sprite = (function() {
  Sprite.getView = function(game, position) {
    var limit, view;
    if (!(game && position)) {
      return;
    }
    limit = [game.width, game.height];
    view = Util.toroidalDelta(position, game.viewOffset, limit);
    view[2] = position[2];
    return view;
  };

  function Sprite(game1, position1, width, height, color) {
    this.game = game1;
    this.position = position1;
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
    this.visible = false;
    this.halfWidth = this.width / 2;
    this.halfHeight = this.height / 2;
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

  Sprite.prototype.getBounds = function() {
    return [[this.view[0] - this.halfWidth, this.view[1] - this.halfHeight], [this.view[0] + this.halfWidth, this.view[1] + this.halfHeight]];
  };

  Sprite.prototype.isInView = function() {
    var ch, cw, h, w;
    w = this.halfWidth * this.game.zoom;
    h = this.halfHeight * this.game.zoom;
    cw = this.game.canvas.width;
    ch = this.game.canvas.height;
    return (this.game.c != null) && (this.view[0] >= -w) && (this.view[1] >= -h) && (this.view[0] <= cw + w) && (this.view[1] <= ch + h);
  };

  Sprite.prototype.updateView = function() {
    if (this.game.c == null) {
      return;
    }
    this.view = Sprite.getView(this.game, this.position);
    if (this.visible = this.isInView()) {
      return this.game.visibleSprites.push(this);
    }
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
    return this.game.c.fillRect(this.view[0] - this.width * this.game.zoom / 2, this.view[1] - this.height * this.game.zoom / 2, this.width * this.game.zoom, this.height * this.game.zoom);
  };

  return Sprite;

})();
