var Player, RingBuffer, Ship;

if (typeof require !== "undefined" && require !== null) {
  RingBuffer = require('./ringbuffer');
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  Player.LOG_LEN = 1 << 8;

  function Player(game, id, socket, position) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    this.ship = new Ship(this, position);
    this.arrows = [];
    this.inputs = [];
    this.inputSequence = 1;
    this.logs = {
      input: new RingBuffer(Player.LOG_LEN),
      state: new RingBuffer(Player.LOG_LEN)
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
    }
  };

  Player.prototype.updateArrows = function() {
    var arrow, i, len, ref, results;
    ref = this.arrows;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      arrow = ref[i];
      results.push(arrow.update());
    }
    return results;
  };

  Player.prototype.update = function() {
    var action, i, len, ref;
    ref = this.inputs;
    for (i = 0, len = ref.length; i < len; i++) {
      action = ref[i];
      if (action != null ? action.length : void 0) {
        this.actions[action].bind(this)();
      }
    }
    this.inputs = [];
    this.ship.update();
    return this.updateArrows();
  };

  return Player;

})();
