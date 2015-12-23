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
    this.visibleSprites = [];
    this.sprites = this.generateSprites();
    this.player = new Player(this, details.id);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.shipState = null;
    this.ships = [];
    this.zoom = 0.25;
    this.inputs = [];
  }

  ClientGame.prototype.interpolation = {
    reset: function(dt) {
      this.interpolation.step = 0;
      return this.interpolation.rate = Client.FRAME_MS / dt;
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

  ClientGame.prototype.processServerData = function(data) {
    var i, inserted, j, k, l, ref, ref1, ref2, ref3, ship, state, vector;
    inserted = false;
    ref = [0, 0], i = ref[0], j = ref[1];
    for (i = k = 0, ref1 = data.ships.length; 0 <= ref1 ? k < ref1 : k > ref1; i = 0 <= ref1 ? ++k : --k) {
      if (data.ships[i].id === this.player.id) {
        this.shipState = data.ships.splice(i, 1)[0];
        break;
      }
    }
    i = 0;
    while (i < data.ships.length && j < this.ships.length) {
      state = data.ships[i];
      ship = this.ships[j];
      if (state.id === ship.id) {
        ship.setState(state.ship);
      } else if (state.id > ship.id) {
        this.ships.splice(j, 1);
        continue;
      } else {
        this.ships.push(new InterpolatedShip(this.player, state.id, state.ship));
        inserted = true;
      }
      i++;
      j++;
    }
    if (j > i) {
      this.ships.length = i;
    } else {
      for (j = l = ref2 = i, ref3 = data.ships.length; ref2 <= ref3 ? l < ref3 : l > ref3; j = ref2 <= ref3 ? ++l : --l) {
        state = data.ships[j];
        this.ships.push(new InterpolatedShip(this.player, state.id, state.ship));
      }
      if (i === 0 && j > 0) {
        ship = this.ships[0];
        console.log('vector to', ship);
        vector = new Vector(this, this.player.ship, ship, "#00f", 0.8, 2, ship.id);
        this.player.vectors.push(vector);
      }
    }
    if (inserted) {
      this.ships.sort(function(a, b) {
        return a.id - b.id;
      });
    }
    this.correctPrediction();
    return this.interpolation.reset.bind(this)(data.tick.dt);
  };

  ClientGame.prototype.update = function() {
    var k, len, ref, ship;
    ref = this.ships;
    for (k = 0, len = ref.length; k < len; k++) {
      ship = ref[k];
      ship.update();
    }
    this.interpolation.step++;
    return ClientGame.__super__.update.call(this);
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.draw = function() {
    var k, l, len, len1, ref, ref1, results, sprite, vector;
    this.clear();
    ref = this.visibleSprites;
    for (k = 0, len = ref.length; k < len; k++) {
      sprite = ref[k];
      sprite.draw();
    }
    this.visibleSprites = [];
    this.player.ship.draw();
    ref1 = this.player.vectors;
    results = [];
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      vector = ref1[l];
      results.push(vector.draw());
    }
    return results;
  };

  ClientGame.prototype.step = function(time) {
    ClientGame.__super__.step.call(this, time);
    return this.draw();
  };

  return ClientGame;

})(Game);
