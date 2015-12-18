var Game, ServerGame, Sprite, Util,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Util = require('./util');

Game = require('./game');

Sprite = require('./sprite');

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
    this.sprites = this.generateStars(numStars);
    this.states = this.getStarStates();
  }

  ServerGame.prototype.generateStars = function(n) {
    var height, i, j, ref, results, width;
    results = [];
    for (i = j = 0, ref = n; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
      width = Util.randomInt(5, 20);
      height = Util.randomInt(5, 20);
      results.push(new Sprite(this, width, height));
    }
    return results;
  };

  ServerGame.prototype.getStarStates = function() {
    var j, len, ref, results, star;
    ref = this.sprites;
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

  ServerGame.prototype.generateShipStates = function() {
    var j, len, player, ref, results;
    ref = this.players;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      results.push({
        id: player.id,
        ship: player.ship.getState()
      });
    }
    return results;
  };

  ServerGame.prototype.update = function() {
    return ServerGame.__super__.update.call(this);
  };

  ServerGame.prototype.step = function(time) {
    ServerGame.__super__.step.call(this, time);
    return this.server.io.emit('state', {
      ships: this.generateShipStates(),
      tick: this.tick
    });
  };

  return ServerGame;

})(Game);
