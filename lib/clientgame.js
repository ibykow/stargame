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
    ref = details.game, this.width = ref.width, this.height = ref.height, this.frictionRate = ref.frictionRate, this.tick = ref.tick, this.states = ref.states;
    ClientGame.__super__.constructor.call(this, this.width, this.height, this.frictionRate);
    this.player = new Player(this, details.player.id, socket);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.sprites = this.generateSprites();
    this.state = {};
  }

  ClientGame.prototype.generateSprites = function() {
    var i, len, ref, results, state;
    ref = this.states;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      state = ref[i];
      results.push(new Sprite(this, state.width, state.height, state.position, state.color));
    }
    return results;
  };

  ClientGame.prototype.updateFromState = function() {
    var myShip;
    if (!this.state.ships) {
      return;
    }
    myShip = (this.state.ships.filter((function(_this) {
      return function(s) {
        return s.id === _this.player.id;
      };
    })(this)))[0].ship;
    this.player.ship.position = myShip.position;
    return this.player.ship.velocity = myShip.velocity;
  };

  ClientGame.prototype.update = function() {
    if (this.state) {
      this.updateFromState();
    }
    ClientGame.__super__.update.call(this);
    return this.draw();
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.draw = function() {
    var color, i, j, len, len1, position, ref, ref1, results, sprite, state;
    this.clear();
    ref = this.sprites;
    for (i = 0, len = ref.length; i < len; i++) {
      sprite = ref[i];
      sprite.draw();
    }
    this.player.ship.draw();
    if (this.state && this.state.ships) {
      ref1 = this.state.ships;
      results = [];
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        state = ref1[j];
        position = state.ship.position;
        color = state.ship.color;
        if (state.id !== this.player.id) {
          results.push(Ship.draw(this.c, position, color));
        } else {
          results.push(void 0);
        }
      }
      return results;
    }
  };

  return ClientGame;

})(Game);
