var Player, Ship;

if (typeof require !== "undefined" && require !== null) {
  Ship = require('./ship');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
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

  Player.prototype.control = {
    forward: function() {},
    reverse: function() {},
    left: function() {},
    right: function() {},
    brake: function() {}
  };

  Player.prototype.processInputs = function() {
    var i, input, len, results;
    results = [];
    for (i = 0, len = inputs.length; i < len; i++) {
      input = inputs[i];
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
