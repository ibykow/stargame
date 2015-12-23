var Player, Ship;

if (typeof require !== "undefined" && require !== null) {
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  function Player(game, id, socket, position) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    this.ship = new Ship(this, position);
    this.vectors = [];
    this.inputs = [];
    this.inputSequence = 0;
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
    }
  };

  Player.prototype.updateVectors = function() {
    var i, len, ref, results, vector;
    ref = this.vectors;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      vector = ref[i];
      results.push(vector.update());
    }
    return results;
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
    this.inputs = [];
    return this.updateVectors();
  };

  return Player;

})();
