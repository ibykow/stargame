var Game, Player, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Player = require('./player');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Game = (function() {
  Game.FRAME_MS = 16;

  function Game(width, height, frictionRate) {
    this.width = width != null ? width : 1 << 8;
    this.height = height != null ? height : 1 << 8;
    this.frictionRate = frictionRate != null ? frictionRate : 0.96;
    this.toroidalLimit = [this.width, this.height];
    this.players = [];
    this.stars = [];
    this.bullets = [];
    this.paused = true;
    this.viewOffset = [0, 0];
    this.tick = {
      count: 0,
      time: 0,
      dt: 0
    };
  }

  Game.prototype.randomPosition = function() {
    return [Util.randomInt(0, this.width), Util.randomInt(0, this.height), 0];
  };

  Game.prototype.newPlayer = function(socket, position) {
    var i;
    i = Util.findEmptySlot(this.players);
    return this.players[i] = new Player(this, i + 1, socket, position);
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

  Game.prototype.updateBullets = function() {
    var bullet, bullets, j, len, ref;
    bullets = [];
    ref = this.bullets;
    for (j = 0, len = ref.length; j < len; j++) {
      bullet = ref[j];
      bullet.update();
      if (bullet.life > 0) {
        bullets.push(bullet);
      }
    }
    return this.bullets = bullets;
  };

  Game.prototype.update = function() {
    return this.updateBullets();
  };

  Game.prototype.logPlayerStates = function() {
    var j, len, player, ref, results;
    ref = this.players;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      if (player) {
        results.push(player.logs['state'].insert({
          sequence: this.tick.count,
          id: player.id,
          ship: player.ship.getState()
        }));
      }
    }
    return results;
  };

  Game.prototype.step = function(time) {
    this.tick.dt = time - this.tick.time;
    this.tick.time = time;
    this.tick.count++;
    return this.update();
  };

  return Game;

})();
