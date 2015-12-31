var Config, Game, GasStation, Player, Server, ServerGame, Sprite, Util, abs, floor, isarr, ref, rnd, round, sqrt, trunc,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Config = require('./config');

Util = require('./util');

Server = require('./server');

Game = require('./game');

Player = require('./player');

Sprite = require('./sprite');

GasStation = require('./gasstation');

Sprite.prototype.updateView = function() {};

Player.LOGLEN = Config.server.updatesPerStep + 1;

ref = [Math.abs, Math.floor, Array.isArray, Math.sqrt, Math.random, Math.round, Math.trunc], abs = ref[0], floor = ref[1], isarr = ref[2], sqrt = ref[3], rnd = ref[4], round = ref[5], trunc = ref[6];

(typeof module !== "undefined" && module !== null ? module : {}).exports = ServerGame = (function(superClass) {
  extend(ServerGame, superClass);

  function ServerGame(server, width1, height1, numStars, frictionRate) {
    var star;
    this.width = width1;
    this.height = height1;
    if (numStars == null) {
      numStars = 10;
    }
    this.frictionRate = frictionRate;
    if (!server) {
      return;
    }
    ServerGame.__super__.constructor.call(this, this.width, this.height, this.frictionRate);
    this.server = server;
    this.stars = this.generateStars(numStars);
    this.starStates = (function() {
      var j, len, ref1, results;
      ref1 = this.stars;
      results = [];
      for (j = 0, len = ref1.length; j < len; j++) {
        star = ref1[j];
        results.push(star.getState());
      }
      return results;
    }).call(this);
    this.page = function() {};
  }

  ServerGame.prototype.generateStars = function(n) {
    var height, i, j, ref1, results, star, width;
    results = [];
    for (i = j = 0, ref1 = n; 0 <= ref1 ? j <= ref1 : j >= ref1; i = 0 <= ref1 ? ++j : --j) {
      width = Util.randomInt(5, 20);
      height = Util.randomInt(5, 20);
      star = new Sprite(this, null, width, height);
      star.id = i;
      if (rnd() < Config.common.rates.gasStations) {
        new GasStation(star);
      }
      results.push(star);
    }
    return results;
  };

  ServerGame.prototype.getShipStates = function() {
    var j, len, player, ref1, results, shipState;
    ref1 = this.players;
    results = [];
    for (j = 0, len = ref1.length; j < len; j++) {
      player = ref1[j];
      shipState = player.ship.getState();
      results.push({
        id: player.id,
        inputSequence: player.inputSequence,
        ship: shipState
      });
    }
    return results;
  };

  ServerGame.prototype.sendState = function() {
    var bullet, bulletStates, shipStates;
    shipStates = this.getShipStates();
    bulletStates = (function() {
      var j, len, ref1, results;
      ref1 = this.bullets;
      results = [];
      for (j = 0, len = ref1.length; j < len; j++) {
        bullet = ref1[j];
        results.push(bullet.getState());
      }
      return results;
    }).call(this);
    return this.server.io.emit('state', {
      ships: shipStates,
      bullets: bulletStates,
      tick: this.tick
    });
  };

  ServerGame.prototype.update = function() {
    var i, j, k, len, logEntry, player, players, ref1;
    for (i = j = 1, ref1 = Config.server.updatesPerStep; 1 <= ref1 ? j <= ref1 : j >= ref1; i = 1 <= ref1 ? ++j : --j) {
      ServerGame.__super__.update.call(this);
      players = this.players.slice();
      for (k = 0, len = players.length; k < len; k++) {
        player = players[k];
        logEntry = player.logs['input'].remove();
        player.inputs = (logEntry != null ? logEntry.inputs : void 0) || [];
        player.update();
        if (!(player.ship.health > 0)) {
          player.die();
        }
      }
      if (players.length === !this.players.length) {
        console.log('Had', players.length, 'players. Now', this.players.length);
      }
    }
    return this.sendState();
  };

  return ServerGame;

})(Game);
