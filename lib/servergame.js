var Game, ServerGame, Sprite, Util,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Util = require('./util');

Game = require('./game');

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
    this.initStates = this.getStarStates();
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

  ServerGame.prototype.generateShipStates = function() {
    var j, len, player, ref, states, synced;
    states = [];
    ref = this.players;
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      if (!(player)) {
        continue;
      }
      synced = !player.clientState || (player.clientState.position[0] === player.ship.position[0]) && (player.clientState.position[1] === player.ship.position[1]) && (player.clientState.position[2] === player.ship.position[2]);
      states.push({
        id: player.id,
        inputSequence: player.inputSequence,
        ship: player.ship.getState(),
        synced: synced
      });
      player.clientState = null;
    }
    return states;
  };

  ServerGame.prototype.prepareInputs = function() {
    var data, j, len, newestData, player, ref, results;
    ref = this.players;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      player = ref[j];
      if (!(player && player.inputs.length)) {
        continue;
      }
      player.inputs.sort(function(a, b) {
        return a.inputSequence - b.inputSequence;
      });
      newestData = player.inputs[player.inputs.length - 1];
      player.inputSequence = newestData.inputSequence;
      player.clientState = newestData.clientState;
      results.push(player.inputs = (function() {
        var k, len1, ref1, results1;
        ref1 = player.inputs;
        results1 = [];
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          data = ref1[k];
          results1.push(data.input);
        }
        return results1;
      })());
    }
    return results;
  };

  ServerGame.prototype.update = function() {
    ServerGame.__super__.update.call(this);
    ServerGame.__super__.update.call(this);
    ServerGame.__super__.update.call(this);
    ServerGame.__super__.update.call(this);
    return ServerGame.__super__.update.call(this);
  };

  ServerGame.prototype.step = function(time) {
    var bullet, bulletStates;
    ServerGame.__super__.step.call(this, time);
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
      ships: this.generateShipStates(),
      bullets: bulletStates,
      tick: this.tick,
      fromServer: true
    });
  };

  return ServerGame;

})(Game);
