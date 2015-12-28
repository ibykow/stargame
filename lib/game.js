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

  Game.prototype.removePlayer = function(p) {
    var i, j, ref;
    if (!(p && p.id)) {
      return;
    }
    for (i = j = 0, ref = this.players.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.players[i].id === p.id) {
        this.players.splice(i, 1);
        return;
      }
    }
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
