var Game, Player, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
  Player = require('./player');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Game = (function() {
  function Game(width, height, frictionRate) {
    this.width = width != null ? width : 1 << 8;
    this.height = height != null ? height : 1 << 8;
    this.frictionRate = frictionRate != null ? frictionRate : 0.96;
    this.toroidalLimit = [this.width, this.height];
    this.players = [];
    this.ships = [];
    this.stars = [];
    this.bullets = [];
    this.paused = true;
    this.viewOffset = [0, 0];
    this.collisionSpriteLists = {
      stars: this.stars,
      ships: this.ships
    };
    this.tick = {
      count: 0,
      time: 0,
      dt: 0
    };
  }

  Game.prototype.framesToMs = function(frames) {
    return frames * Config.common.msPerFrame;
  };

  Game.prototype.msToFrames = function(ms) {
    return ms / Config.common.msPerFrame;
  };

  Game.prototype.randomPosition = function() {
    return [Util.randomInt(0, this.width), Util.randomInt(0, this.height), 0];
  };

  Game.prototype.removePlayer = function(p) {
    var i, j, ref, results;
    if (!p) {
      return;
    }
    results = [];
    for (i = j = 0, ref = this.players.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.players[i].id === p.id) {
        this.players.splice(i, 1);
        break;
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  Game.prototype.insertBullet = function(b) {
    if (!b) {
      return;
    }
    return this.bullets.push(b);
  };

  Game.prototype.getShips = function() {
    return this.players.map(function(p) {
      return p.ship;
    });
  };

  Game.prototype.update = function() {
    var b, j, len, ref, results;
    this.tick.count++;
    ref = this.bullets;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      b = ref[j];
      results.push(b.update());
    }
    return results;
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
    return this.tick.time = time;
  };

  return Game;

})();
