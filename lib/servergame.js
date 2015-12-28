var Game, Player, Server, ServerGame, Sprite, Util,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Util = require('./util');

Server = require('./server');

Game = require('./game');

Player = require('./player');

Sprite = require('./sprite');

Sprite.prototype.updateView = function() {};

(typeof module !== "undefined" && module !== null ? module : {}).exports = ServerGame = (function(superClass) {
  extend(ServerGame, superClass);

  function ServerGame(server, width1, height1, numStars, frictionRate) {
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
    this.starStates = this.getStarStates();
    Player.LOGLEN = Server.FRAMES_PER_STEP;
  }

  ServerGame.prototype.generateStars = function(n) {
    var height, i, j, ref, results, width;
    results = [];
    for (i = j = 0, ref = n; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
      width = Util.randomInt(5, 20);
      height = Util.randomInt(5, 20);
      results.push(new Sprite(this, null, width, height));
    }
    return results;
  };

  ServerGame.prototype.getStarStates = function() {
    var j, len, ref, results, star;
    ref = this.stars;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      star = ref[j];
      results.push({
        position: star.position,
        width: star.width,
        height: star.height,
        color: star.color
      });
    }
    return results;
  };

  ServerGame.prototype.getShipStates = function() {
    var j, len, player, ref, results;
    ref = this.players;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      if (player) {
        results.push({
          id: player.id,
          inputSequence: player.inputSequence,
          ship: player.ship.getState()
        });
      }
    }
    return results;
  };

  ServerGame.prototype.updateClients = function() {
    var bullet, bulletStates, shipStates;
    shipStates = this.getShipStates();
    bulletStates = (function() {
      var j, len, ref, results;
      ref = this.bullets;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        bullet = ref[j];
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
    ServerGame.__super__.update.call(this);
    return this.updateClients();
  };

  return ServerGame;

})(Game);
