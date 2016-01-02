var Config, Eventable, Player, RingBuffer, Ship, Util, pesoChar,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
  Eventable = require('./eventable');
  RingBuffer = require('./ringbuffer');
  Ship = require('./ship');
}

pesoChar = Config.common.chars.peso;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function(superClass) {
  extend(Player, superClass);

  Player.LOGLEN = Config.client.player.loglen;

  function Player(game, socket, position) {
    this.game = game;
    this.socket = socket;
    Player.__super__.constructor.call(this, this.game);
    this.ship = new Ship(this, position);
    this.arrows = [];
    this.inputs = [];
    this.cash = 3000;
    this.minInputSequence = 1;
    this.inputSequence = 1;
    this.logs = {
      state: new RingBuffer(Player.LOGLEN),
      input: new RingBuffer(Player.LOGLEN)
    };
  }

  Player.prototype.actions = {
    forward: function() {
      return this.ship.forward();
    },
    reverse: function() {
      return this.ship.reverse();
    },
    left: function() {
      return this.ship.left();
    },
    right: function() {
      return this.ship.right();
    },
    brake: function() {
      return this.ship.brake();
    },
    fire: function() {
      return this.ship.fire();
    },
    refuel: function() {
      var fuelDelta, info, price, station;
      if (!Util.isNumeric(this.game.gasStationID)) {
        return;
      }
      station = this.game.stars[this.game.gasStationID].children['GasStation'];
      if (!station) {
        return this.game.page("Gas station out of order. Sorry.");
      }
      if (this.ship.distanceTo(station) > Config.common.fuel.distance) {
        return this.game.page('Sorry. The gas station is too far away.');
      }
      if (!(this.cash > 0)) {
        return this.game.page("Sorry, you're broke.");
      }
      fuelDelta = this.ship.fuelCapacity - this.ship.fuel;
      if (!(fuelDelta > 0)) {
        return this.game.page("You're full!");
      }
      price = fuelDelta * station.fuelPrice;
      if (price > this.cash) {
        fuelDelta = this.cash / station.fuelPrice;
        price = this.cash;
      }
      this.cash -= price;
      this.ship.fuel += fuelDelta;
      info = 'You bought ' + fuelDelta.toFixed(2) + 'L of fuel for ' + pesoChar + price.toFixed(2) + ' at ' + pesoChar + station.fuelPrice.toFixed(2) + '/L';
      return this.game.page(info);
    }
  };

  Player.prototype.arrowTo = function(sprite, id, color) {
    if (color == null) {
      color = '#00F';
    }
    return this.arrows.push(new Arrow(this.game, this.ship, sprite, color, 0.8, 2, id));
  };

  Player.prototype.getState = function() {
    return Object.assign(Player.__super__.getState.call(this), {
      inputSequence: this.inputSequence,
      ship: this.ship.getState()
    });
  };

  Player.prototype.setState = function(state) {
    Player.__super__.setState.call(this, state);
    this.inputSequence = state.inputSequence;
    return this.ship.setState(state.ship);
  };

  Player.prototype.die = function() {
    console.log("I'm dead", this.id);
    return this.socket.disconnect();
  };

  Player.prototype.updateArrows = function() {
    var arrow, arrows, i, j, len, results;
    arrows = this.arrows.slice();
    results = [];
    for (i = j = 0, len = arrows.length; j < len; i = ++j) {
      arrow = arrows[i];
      if (arrow.b.flags.isDeleted) {
        results.push(this.arrows.splice(i, 1));
      } else {
        results.push(arrow.update());
      }
    }
    return results;
  };

  Player.prototype.updateInputLog = function() {
    var entry;
    entry = {
      sequence: this.inputSequence,
      gameStep: this.game.tick.count,
      serverStep: this.game.serverTick.count,
      ship: this.ship.getState(),
      inputs: this.inputs.slice(),
      gasStationID: this.game.gasStationID
    };
    this.logs['input'].insert(entry);
    this.latestInputLogEntry = entry;
    return this.inputSequence++;
  };

  Player.prototype.update = function() {
    var action, j, len, ref;
    ref = this.inputs;
    for (j = 0, len = ref.length; j < len; j++) {
      action = ref[j];
      if (!(action != null ? action.length : void 0)) {
        continue;
      }
      this.emit(action, this.getState());
      this.actions[action].bind(this)();
    }
    this.ship.update();
    if (this.ship.health < 0) {
      return this.die();
    }
  };

  return Player;

})(Eventable);
