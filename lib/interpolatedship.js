var InterpolatedShip, Sprite, Util,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Sprite = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = InterpolatedShip = (function(superClass) {
  extend(InterpolatedShip, superClass);

  function InterpolatedShip(player, state) {
    this.player = player;
    if (!(this.player && state.position)) {
      return null;
    }
    InterpolatedShip.__super__.constructor.call(this, this.player, state.position);
    this.velocity = state.velocity;
    this.color = state.color;
    this.prev = state;
    this.next = state;
  }

  InterpolatedShip.prototype.updateVelocity = function() {};

  InterpolatedShip.prototype.updatePosition = function() {
    var rate;
    rate = this.game.interpolation.rate * this.game.interpolation.step;
    return this.position = Util.lerp(this.prev.position, this.next.position, rate);
  };

  InterpolatedShip.prototype.setState = function(state) {
    this.prev = {
      position: this.next.position,
      width: this.next.velocity,
      height: this.next.height,
      color: this.next.color
    };
    return this.next = state;
  };

  return InterpolatedShip;

})(Ship);
