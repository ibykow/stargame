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
    this.player = new Player(this, details.id);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.visibleSprites = [];
    this.sprites = this.generateSprites();
    this.prevState = null;
    this.nextState = null;
    this.shipState = null;
    this.inputs = [];
  }

  ClientGame.prototype.interpolation = {
    reset: function() {
      this.interpolation.step = 0;
      return this.interpolation.rate = Client.FRAME_MS / this.nextState.tick.dt;
    }
  };

  ClientGame.prototype.generateSprites = function() {
    var k, len, ref, results, state;
    ref = this.initStates;
    results = [];
    for (k = 0, len = ref.length; k < len; k++) {
      state = ref[k];
      results.push(new Sprite(this, state.position, state.width, state.height, state.color));
    }
    return results;
  };

  ClientGame.prototype.correctPrediction = function() {
    var i, k, ref, ref1, temp;
    if (!((ref = this.shipState) != null ? ref.inputSequence : void 0)) {
      return;
    }
    if (this.shipState.synced) {
      if (this.inputs.length > 20) {
        this.inputs.splice(0, this.inputs.length - 20);
      }
      return;
    }
    this.player.ship.setState(this.shipState.ship);
    i = 0;
    for (i = k = 0, ref1 = this.inputs.length; 0 <= ref1 ? k < ref1 : k > ref1; i = 0 <= ref1 ? ++k : --k) {
      if (this.inputs[i].inputSequence == null) {
        console.log('invalid inputEntry');
      }
      if (this.inputs[i].inputSequence >= this.shipState.inputSequence) {
        break;
      }
    }
    this.inputs.splice(0, i);
    if (this.inputs.length) {
      temp = this.inputs.map(function(e) {
        return e.input;
      });
      if (Array.isArray(this.player.inputs[0]) || (this.player.inputs.length === 0)) {
        return this.player.inputs = temp.concat(this.player.inputs);
      } else {
        return this.player.inputs = this.player.inputs.push(temp);
      }
    }
  };

  ClientGame.prototype.processStates = function() {
    var i, j, ref;
    this.nextState.processed = true;
    ref = [0, 0], i = ref[0], j = ref[1];
    while (i < this.nextState.ships.length) {
      if (this.nextState.ships[i].id === this.player.id) {
        this.shipState = this.nextState.ships.splice(i, 1)[0];
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
    return this.correctPrediction();
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
    var color, inter, k, l, len, len1, len2, m, nextState, prevState, rate, ref, ref1, ref2, results, sprite, state, vector, view;
    this.clear();
    ref = this.visibleSprites;
    for (k = 0, len = ref.length; k < len; k++) {
      sprite = ref[k];
      sprite.draw();
    }
    this.visibleSprites = [];
    this.player.ship.draw();
    ref1 = this.player.vectors;
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      vector = ref1[l];
      vector.draw();
    }
    ref2 = this.nextState.ships;
    results = [];
    for (m = 0, len2 = ref2.length; m < len2; m++) {
      state = ref2[m];
      if (!state.prevState) {
        Ship.draw(this.c, state.ship.position, state.ship.color);
        continue;
      }
      nextState = state.ship;
      prevState = state.prevState.ship;
      rate = this.interpolation.rate * this.interpolation.step;
      this.interpolation.step++;
      inter = Sprite.interpolate.bind(this)(prevState, nextState, rate);
      view = Sprite.getView(this, inter.position);
      color = state.ship.color;
      results.push(Ship.draw(this.c, view, color));
    }
    return results;
  };

  return ClientGame;

})(Game);
