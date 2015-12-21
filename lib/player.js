var Player, Ship;

if (typeof require !== "undefined" && require !== null) {
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  Player.TURN_RATE = 0.06;

  function Player(game, id, socket, position) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    console.log('player', position);
    this.ship = new Ship(this, position);
    this.inputs = [];
    this.inputSequence = 0;
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

  Player.prototype.update = function() {
    var act, i, input, j, len, len1, ref;
    if (!(this.inputs.length && Array.isArray(this.inputs[0]))) {
      this.inputs = [this.inputs];
    }
    ref = this.inputs;
    for (i = 0, len = ref.length; i < len; i++) {
      input = ref[i];
      for (j = 0, len1 = input.length; j < len1; j++) {
        act = input[j];
        if (input.length && (act != null ? act.length : void 0)) {
          this.actions[act].bind(this)();
        }
      }
      this.ship.update();
    }
    return this.inputs = [];
  };

  return Player;

})();
