var Player, Ship;

if (typeof require !== "undefined" && require !== null) {
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  Player.TURN_RATE = 0.1;

  function Player(game, id, socket) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    this.ship = new Ship(this);
    this.inputs = [];
  }

  Player.prototype.actions = {
    forward: function() {
      return this.ship.gear = 1;
    },
    reverse: function() {
      return this.ship.gear = -1;
    },
    left: function() {
      return this.ship.position[2] += Player.TURN_RATE;
    },
    right: function() {
      return this.ship.position[2] -= Player.TURN_RATE;
    },
    brake: function() {
      return this.ship.brake = true;
    }
  };

  Player.prototype.processInputs = function() {
    var i, input, len, ref, results;
    ref = this.inputs;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      input = ref[i];
      results.push(this.control[input].bind(this)());
    }
    return results;
  };

  Player.prototype.update = function() {
    this.processInputs();
    return this.ship.update();
  };

  return Player;

})();
