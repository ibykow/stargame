var Game, Player;

if (typeof require !== "undefined" && require !== null) {
  Player = require('./player');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Game = (function() {
  function Game(width, height) {
    this.width = width != null ? width : 1025;
    this.height = height != null ? height : 1025;
    this.players = [];
    this.sprites = [];
    this.paused = true;
    this.tick = {
      count: 0,
      time: 0,
      dt: 0
    };
  }

  Game.prototype.getOpenPlayerSlot = function() {
    var j, ref, slot;
    for (slot = j = 0, ref = this.players.length; 0 <= ref ? j <= ref : j >= ref; slot = 0 <= ref ? ++j : --j) {
      if (!this.players[slot]) {
        return slot;
      }
    }
  };

  Game.prototype.newPlayer = function(socket) {
    var i;
    i = this.getOpenPlayerSlot();
    return this.players[i] = new Player(this, i + 1, socket);
  };

  Game.prototype.removePlayer = function(p) {
    var results;
    if (!(p && p.id)) {
      return;
    }
    this.players[p.id - 1] = null;
    results = [];
    while (this.players.length && !this.players[this.players.length - 1]) {
      results.push(this.players.length--);
    }
    return results;
  };

  Game.prototype.update = function() {
    var j, k, len, len1, player, ref, ref1, results, sprite;
    ref = this.players;
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      player.update();
    }
    ref1 = this.sprites;
    results = [];
    for (k = 0, len1 = ref1.length; k < len1; k++) {
      sprite = ref1[k];
      results.push(sprite.update());
    }
    return results;
  };

  Game.prototype.draw = function() {};

  Game.prototype.step = function(time) {
    this.tick.count++;
    this.tick.dt = time - this.tick.time;
    this.tick.time = time;
    this.update;
    return this.draw;
  };

  return Game;

})();
