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
    var j, k, len, len1, player, ref, ref1, results, star;
    ref = this.stars;
    for (j = 0, len = ref.length; j < len; j++) {
      star = ref[j];
      star.update();
    }
    this.updateBullets();
    ref1 = this.players;
    results = [];
    for (k = 0, len1 = ref1.length; k < len1; k++) {
      player = ref1[k];
      if (player) {
        results.push(player.update());
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
