var Player, Ship;

if (typeof require !== "undefined" && require !== null) {
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  Player.TURN_RATE = 0.06;

  function Player(game, id, socket) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    this.ship = new Ship(this);
    this.input = [];
  }

  Player.prototype.actions = {
    forward: function() {
      this.ship.velocity[0] += Math.cos(this.ship.position[2]);
      return this.ship.velocity[1] += Math.sin(this.ship.position[2]);
    },
    reverse: function() {
      this.ship.velocity[0] -= Math.cos(this.ship.position[2]);
      return this.ship.velocity[1] -= Math.sin(this.ship.position[2]);
    },
    left: function() {
      return this.ship.position[2] -= Player.TURN_RATE;
    },
    right: function() {
      return this.ship.position[2] += Player.TURN_RATE;
    },
    brake: function() {
      this.ship.velocity[0] *= Ship.BRAKE_RATE;
      return this.ship.velocity[1] *= Ship.BRAKE_RATE;
    }
  };

  Player.prototype.processInput = function() {
    var action, i, len, ref;
    if (!this.input.length) {
      return;
    }
    ref = this.input;
    for (i = 0, len = ref.length; i < len; i++) {
      action = ref[i];
      this.actions[action].bind(this)();
    }
    return this.input = [];
  };

  Player.prototype.update = function() {
    this.processInput();
    return this.ship.update();
  };

  return Player;

})();
