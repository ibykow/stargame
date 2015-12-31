var Button, Config, Sprite, Util, abs, cfg, floor, isarr, ref, rnd, round, sqrt, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Config = require('./config');
  Sprite = require('./sprite');
}

ref = [Math.abs, Math.floor, Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc], abs = ref[0], floor = ref[1], isarr = ref[2], sqrt = ref[3], rnd = ref[4], round = ref[5], trunc = ref[6];

cfg = Config.common.button;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Button = (function(superClass) {
  extend(Button, superClass);

  function Button(parent, name, click, text, params) {
    var colors, height, ref1, width;
    this.parent = parent;
    this.text = text != null ? text : 'OK';
    this.params = params != null ? params : cfg;
    if (!this.parent) {
      return;
    }
    ref1 = this.params, width = ref1.width, height = ref1.height, colors = ref1.colors;
    Button.__super__.constructor.call(this, this.parent.game, this.parent.position, width, height, colors.background);
    this.parent.adopt(this, name);
    click = click != null ? click : function() {
      return console.log('Hello, World');
    };
    this.mouse.click = (function(_this) {
      return function() {
        _this.color = colors.click;
        return click(_this);
      };
    })(this);
    this.enabled = this.params["default"].enabled;
  }

  Button.prototype.updatePosition = function() {
    return this.position = [this.parent.position[0] + this.params.offset[0], this.parent.position[1] + this.params.offset[1], this.parent.position[2]];
  };

  Button.prototype.update = function() {
    Button.__super__.update.call(this);
    if (this.mouse.hovering) {
      return this.color = this.params.colors.hover;
    } else {
      return this.color = this.params.colors.background;
    }
  };

  Button.prototype.isInView = function() {
    return this.enabled && Button.__super__.isInView.call(this);
  };

  Button.prototype.draw = function() {
    var xoff, yoff;
    if (!this.enabled) {
      return;
    }
    xoff = -this.halfWidth;
    yoff = -this.halfHeight;
    this.game.c.fillStyle = this.color;
    this.game.c.fillRect(this.view[0] + xoff, this.view[1] + yoff, this.width, this.height);
    this.game.c.fillStyle = this.params.colors.text;
    this.game.c.font = this.params.font.string;
    return this.game.c.fillText(this.text, this.view[0] + this.params.font.offset[0] + xoff, this.view[1] + this.params.font.offset[1]);
  };

  return Button;

})(Sprite);
