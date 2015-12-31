var Config, Player, RingBuffer, Ship, Util, pesoChar;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
  RingBuffer = require('./ringbuffer');
  Ship = require('./ship');
}

pesoChar = Config.common.chars.peso;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  Player.LOGLEN = Config.client.player.loglen;

  function Player(game, id1, socket, position) {
    this.game = game;
    this.id = id1;
    this.socket = socket;
    if (!this.game) {
      return null;
    }
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
      info = "You bought " + fuelDelta.toFixed(2) + "L of fuel for " + pesoChar + price.toFixed(2) + " at " + pesoChar + station.fuelPrice.toFixed(2);
      return this.game.page(info);
    }
  };

  Player.prototype.die = function() {
    return this.socket.disconnect();
  };

  Player.prototype.arrowTo = function(sprite, id, color) {
    if (color == null) {
      color = '#00F';
    }
    return this.arrows.push(new Arrow(this.game, this.ship, sprite, color, 0.8, 2, id));
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
      if (action != null ? action.length : void 0) {
        this.actions[action].bind(this)();
      }
    }
    return this.ship.update();
  };

  return Player;

})();
