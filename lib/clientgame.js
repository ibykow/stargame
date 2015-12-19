var Client, ClientGame, Game, Ship, Sprite,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
  Ship = require('./ship');
  Game = require('./game');
  Client = require('./client');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = ClientGame = (function(superClass) {
  extend(ClientGame, superClass);

  function ClientGame(details, canvas, c, socket) {
    var ref;
    this.canvas = canvas;
    this.c = c;
    if (!details) {
      return;
    }
    ClientGame.__super__.constructor.call(this, details.game.width, details.game.height, details.game.frictionRate);
    ref = details.game, this.tick = ref.tick, this.initStates = ref.initStates;
    this.player = new Player(this, details.player.id, socket);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.loops = [];
    this.sprites = this.generateSprites();
    this.prevState = null;
    this.nextState = null;
    this.inputs = [];
  }

  ClientGame.prototype.interpolation = {
    reset: function() {
      this.interpolation.step = 0;
      return this.interpolation.rate = Client.FRAME_MS / this.nextState.tick.dt;
    },
    step: 0,
    rate: 0
  };

  ClientGame.prototype.generateSprites = function() {
    var k, len, ref, results, state;
    ref = this.initStates;
    results = [];
    for (k = 0, len = ref.length; k < len; k++) {
      state = ref[k];
      results.push(new Sprite(this, state.width, state.height, state.position, state.color));
    }
    return results;
  };

  ClientGame.prototype.correctPrediction = function(shipState, tick) {
    this.player.ship.setState(shipState);
    if (!(this.inputs.length && tick.count >= this.inputs[0].tick.count)) {
      return;
    }
    while (i < this.inputs.length) {
      if (this.inputs[i].tick.count >= tick.count) {
        break;
      }
    }
    this.inputs.splice(0, i);
    this.player.input = (this.inputs.reduce((function(p, n) {
      return p.concat(n.input);
    }), [])).concat(this.player.input);
    return this.player.input.length;
  };

  ClientGame.prototype.processStates = function() {
    var i, j, loops, ref, shipState;
    if (this.nextState.processed) {
      return;
    }
    this.nextState.processed = true;
    ref = [0, 0, null], i = ref[0], j = ref[1], shipState = ref[2];
    loops = 0;
    while (i < this.nextState.ships.length) {
      loops++;
      if (this.nextState.ships[i].id === this.player.id) {
        shipState = this.nextState.ships.splice(i, 1);
        continue;
      }
      if (j >= this.prevState.ships.length) {
        return;
      }
      if (this.nextState.ships[i].id === this.prevState.ships[j].id) {
        this.nextState.ships[i].prevState = {
          id: this.prevState.ships[j].id,
          ship: this.prevState.ships[j].ship
        };
      } else if (this.nextState.ships[i].id > this.prevState.ships[j].id) {
        j++;
        continue;
      }
      i++;
    }
    if (!!shipState) {
      this.correctPrediction(shipState, this.nextState.tick);
    }
    return this.loops.push(loops);
  };

  ClientGame.prototype.update = function() {
    ClientGame.__super__.update.call(this);
    return this.draw();
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.draw = function() {
    var color, inter, k, l, len, len1, nextState, prevState, rate, ref, ref1, results, sprite, state;
    this.clear();
    ref = this.sprites;
    for (k = 0, len = ref.length; k < len; k++) {
      sprite = ref[k];
      sprite.draw();
    }
    this.player.ship.draw();
    ref1 = this.nextState.ships;
    results = [];
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      state = ref1[l];
      if (!state.prevState) {
        Ship.draw(this.c, state.ship.position, state.ship.color);
        continue;
      }
      nextState = state.ship;
      prevState = state.prevState.ship;
      rate = this.interpolation.rate * this.interpolation.step;
      this.interpolation.step++;
      inter = Sprite.interpolate.bind(this)(prevState, nextState, rate);
      color = state.ship.color;
      results.push(Ship.draw(this.c, inter.position, color));
    }
    return results;
  };

  return ClientGame;

})(Game);
