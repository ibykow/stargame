var ClientGame, Game, Ship, Sprite,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
  Ship = require('./ship');
  Game = require('./game');
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
    ref = details.game, this.tick = ref.tick, this.states = ref.states;
    this.player = new Player(this, details.player.id, socket);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.sprites = this.generateSprites();
    this.state = {
      tick: this.tick,
      ships: [],
      processed: true
    };
    this.inputs = [];
  }

  ClientGame.prototype.generateSprites = function() {
    var j, len, ref, results, state;
    ref = this.states;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      state = ref[j];
      results.push(new Sprite(this, state.width, state.height, state.position, state.color));
    }
    return results;
  };

  ClientGame.prototype.correctPrediction = function(shipState, tick) {
    var i, j, ref;
    this.player.ship.setState(shipState);
    if (tick.count >= this.tick.count) {
      this.tick = tick;
      this.inputs = [];
    }
    if (!(this.inputs.length && tick.count >= this.inputs[0].tick.count)) {
      return;
    }
    i = 0;
    for (i = j = 0, ref = this.inputs.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.inputs[i].tick.count < tick.count) {
        i;
      }
    }
    this.inputs.splice(0, i);
    this.player.input = (this.inputs.reduce((function(p, n) {
      return p.concat(n.input);
    }), [])).concat(this.player.input);
    return this.player.input.length;
  };

  ClientGame.prototype.processState = function() {
    var i, j, ref, shipState;
    if (this.state.processed) {
      return;
    }
    this.state.processed = true;
    i = 0;
    for (i = j = 0, ref = this.state.ships.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.state.ships[i].id === this.player.id) {
        break;
      }
    }
    shipState = this.state.ships.splice(i, 1);
    if (!!shipState) {
      return this.correctPrediction(shipState, this.state.tick);
    }
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
    var color, j, k, len, len1, position, ref, ref1, results, sprite, state;
    this.clear();
    ref = this.sprites;
    for (j = 0, len = ref.length; j < len; j++) {
      sprite = ref[j];
      sprite.draw();
    }
    this.player.ship.draw();
    ref1 = this.state.ships;
    results = [];
    for (k = 0, len1 = ref1.length; k < len1; k++) {
      state = ref1[k];
      position = state.ship.position;
      color = state.ship.color;
      if (state.id !== this.player.id) {
        results.push(Ship.draw(this.c, position, color));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  ClientGame.prototype.step = function(time) {
    this.processState();
    return ClientGame.__super__.step.call(this, time);
  };

  return ClientGame;

})(Game);
