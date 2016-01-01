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
    this.page = console.log;
    this.newBullets = [];
  }

  ServerGame.prototype.insertBullet = function(b) {
    if (!ServerGame.__super__.insertBullet.call(this, b)) {
      return;
    }
    return this.newBullets.push(b);
  };

  ServerGame.prototype.generateStars = function(n) {
    var height, i, j, ref1, results, star, width;
    results = [];
    for (i = j = 0, ref1 = n; 0 <= ref1 ? j <= ref1 : j >= ref1; i = 0 <= ref1 ? ++j : --j) {
      width = Util.randomInt(5, 20);
      height = Util.randomInt(5, 20);
      star = new Sprite(this, null, width, height);
      star.id = i;
      if (rnd() < Config.common.rates.gasStation) {
        new GasStation(star);
      }
      results.push(star);
    }
    return results;
  };

  ServerGame.prototype.getShipStates = function() {
    var j, len, player, ref1, results, state;
    ref1 = this.players;
    results = [];
    for (j = 0, len = ref1.length; j < len; j++) {
      player = ref1[j];
      state = player.ship.getState();
      results.push({
        id: player.id,
        inputSequence: player.inputSequence,
        ship: state
      });
    }
    return results;
  };

  ServerGame.prototype.sendInitialState = function(player) {
    var bullet, bulletStates, shipStates;
    if (!player) {
      return;
    }
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
    return player.socket.emit('welcome', {
      id: player.id,
      bullets: bulletStates,
      ships: shipStates,
      game: {
        width: this.width,
        height: this.height,
        frictionRate: this.frictionRate,
        tick: this.tick,
        starStates: this.starStates
      }
    });
  };

  ServerGame.prototype.sendState = function() {
    var bullet, bulletStates, shipStates;
    shipStates = this.getShipStates();
    bulletStates = (function() {
      var j, len, ref1, results;
      ref1 = this.newBullets;
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
      game: {
        tick: this.tick
      }
    });
  };

  ServerGame.prototype.update = function() {
    var i, j, ref1;
    for (i = j = ref1 = Config.server.updatesPerStep; ref1 <= 1 ? j <= 1 : j >= 1; i = ref1 <= 1 ? ++j : --j) {
      ServerGame.__super__.update.call(this);
    }
    this.sendState();
    return this.newBullets = [];
  };

  ServerGame.prototype.step = function() {
    ServerGame.__super__.step.call(this);
    return this.update();
  };

  return ServerGame;

})(Game);
