var Config, GasStation, Sprite, Util, abs, floor, isarr, ref, rnd, round, sqrt, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Config = require('./config');
  Sprite = require('./sprite');
}

ref = [Math.abs, Math.floor, Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc], abs = ref[0], floor = ref[1], isarr = ref[2], sqrt = ref[3], rnd = ref[4], round = ref[5], trunc = ref[6];

(typeof module !== "undefined" && module !== null ? module : {}).exports = GasStation = (function(superClass) {
  extend(GasStation, superClass);

  function GasStation(parent, fuelPrice) {
    this.parent = parent;
    this.fuelPrice = fuelPrice;
    if (!this.parent) {
      return;
    }
    GasStation.__super__.constructor.call(this, this.parent.game, this.parent.position, 20, 20);
    if (this.fuelPrice == null) {
      this.fuelPrice = Config.common.fuel.price.min + rnd() * (Config.common.fuel.price.max - Config.common.fuel.price.min);
    }
    this.parent.adopt(this);
    this.position = this.parent.position;
  }

  GasStation.prototype.getState = function() {
    var state;
    state = GasStation.__super__.getState.call(this);
    return state.fuelPrice = this.fuelPrice;
  };

  GasStation.prototype.setState = function(state) {
    var ref1;
    GasStation.__super__.setState.call(this, state);
    return this.fuelPrice = (ref1 = state.fuelPrice) != null ? ref1 : this.fuelPrice;
  };

  GasStation.prototype.draw = function() {
    this.game.c.fillStyle = "#0f0";
    this.game.c.font = "14px Courier New";
    return this.game.c.fillText('G', this.view[0] + this.parent.halfWidth, this.view[1]);
  };

  return GasStation;

})(Sprite);
