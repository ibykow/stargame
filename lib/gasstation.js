var Button, Config, GasStation, Sprite, Util, abs, floor, isarr, pesoChar, ref, rnd, round, sqrt, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Config = require('./config');
  Sprite = require('./sprite');
  Button = require('./button');
}

ref = [Math.abs, Math.floor, Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc], abs = ref[0], floor = ref[1], isarr = ref[2], sqrt = ref[3], rnd = ref[4], round = ref[5], trunc = ref[6];

pesoChar = Config.common.chars.peso;

(typeof module !== "undefined" && module !== null ? module : {}).exports = GasStation = (function(superClass) {
  extend(GasStation, superClass);

  function GasStation(parent1, fuelPrice1, buttonState) {
    var params;
    this.parent = parent1;
    this.fuelPrice = fuelPrice1;
    this.buttonState = buttonState;
    if (!this.parent) {
      return;
    }
    GasStation.__super__.constructor.call(this, this.parent.game, this.parent.position, 9, 9);
    if (this.fuelPrice == null) {
      this.fuelPrice = Config.common.fuel.price.min + rnd() * (Config.common.fuel.price.max - Config.common.fuel.price.min);
    }
    this.parent.adopt(this);
    if (this.buttonState) {
      this.appendButton(this.buttonState);
    } else {
      params = Config.common.button;
      params.width = 160;
      params.height = 32;
      params["default"].enabled = false;
      this.buttonState = {
        text: 'Fill up for ' + pesoChar + this.fuelPrice.toFixed(2) + '/L',
        params: params
      };
    }
  }

  GasStation.fromState = function(parent, state) {
    return new GasStation(parent, state.fuelPrice, state.button);
  };

  GasStation.prototype.appendButton = function(state) {
    var button;
    this.click = (function(_this) {
      return function(b) {
        if (!b.enabled) {
          return;
        }
        b.enabled = false;
        _this.game.gasStationID = _this.parent.id;
        return _this.game.player.inputs.push('refuel');
      };
    })(this);
    button = new Button(this, 'fillUpButton', this.click, state.text, state.params);
    this.mouse.enter = function() {
      return button.enabled = true;
    };
    return button.mouse.leave = function() {
      return button.enabled = false;
    };
  };

  GasStation.prototype.getState = function() {
    var button, fuelPrice;
    return Object.assign(GasStation.__super__.getState.call(this), fuelPrice = this.fuelPrice, button = this.buttonState);
  };

  GasStation.prototype.setState = function(state) {
    GasStation.__super__.setState.call(this, state);
    return this.fuelPrice = state.fuelPrice, this.buttonState = state.buttonState, state;
  };

  GasStation.prototype.updatePosition = function() {
    return this.position = [this.parent.position[0], this.parent.position[1] - 9, this.parent.position[2]];
  };

  GasStation.prototype.draw = function() {
    this.game.c.fillStyle = "#0f0";
    this.game.c.font = "14px Courier New";
    return this.game.c.fillText('G', this.view[0] - 5, this.view[1]);
  };

  return GasStation;

})(Sprite);
