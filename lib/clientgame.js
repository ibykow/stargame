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
    this.mouseSprites = [];
    this.stars = this.generateStars();
    this.player = new Player(this, details.id);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.shipState = null;
    this.ships = [];
    this.zoom = 1;
    this.inputLog = [];
  }

  ClientGame.prototype.interpolation = {
    reset: function(dt) {
      this.interpolation.step = 0;
      return this.interpolation.rate = Client.FRAME_MS / dt;
    }
  };

  ClientGame.prototype.generateStars = function() {
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
    var entry, i, k, l, len, ref, ref1, ref2, results;
    if (!((ref = this.shipState) != null ? ref.inputSequence : void 0)) {
      return;
    }
    if (this.shipState.synced) {
      if (this.inputLog.length > 20) {
        this.inputLog.splice(0, this.inputLog.length - 20);
      }
      return;
    }
    i = 0;
    for (i = k = 0, ref1 = this.inputLog.length; 0 <= ref1 ? k < ref1 : k > ref1; i = 0 <= ref1 ? ++k : --k) {
      if (this.inputLog[i].inputSequence == null) {
        console.log('invalid inputEntry');
      }
      if (this.inputLog[i].inputSequence >= this.shipState.inputSequence) {
        break;
      }
    }
    this.inputLog.splice(0, i);
    this.player.ship.setState(this.shipState.ship);
    ref2 = this.inputLog;
    results = [];
    for (l = 0, len = ref2.length; l < len; l++) {
      entry = ref2[l];
      this.game.player.inputs = entry.inputs;
      results.push(this.game.player.update());
    }
    return results;
  };

  ClientGame.prototype.processServerData = function(data) {
    var arrow, i, inserted, j, k, l, ref, ref1, ref2, ref3, ship, state;
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
        console.log('arrow to', ship);
        arrow = new Arrow(this, this.player.ship, ship, "#00f", 0.8, 2, ship.id);
        this.player.arrows.push(arrow);
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

  ClientGame.prototype.isMouseInBounds = function(bounds) {
    return Util.isInSquareBounds([this.client.mouse.x, this.client.mouse.y], bounds);
  };

  ClientGame.prototype.moveMouse = function() {
    var k, l, len, len1, prevSprites, ref, results, sprite;
    prevSprites = this.mouseSprites;
    this.mouseSprites = [];
    ref = this.visibleSprites;
    for (k = 0, len = ref.length; k < len; k++) {
      sprite = ref[k];
      if (!this.isMouseInBounds(sprite.getBounds())) {
        continue;
      }
      this.mouseSprites.push(sprite);
      sprite.mouse.hovering = true;
      if ((sprite.mouse.enter != null) && !~prevSprites.indexOf(sprite)) {
        sprite.mouse.enter.bind(sprite)();
      }
    }
    results = [];
    for (l = 0, len1 = prevSprites.length; l < len1; l++) {
      sprite = prevSprites[l];
      if (~this.mouseSprites.indexOf(sprite) !== 0) {
        continue;
      }
      sprite.mouse.hovering = false;
      if (sprite.mouse.leave != null) {
        results.push(sprite.mouse.leave.bind(sprite)());
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  ClientGame.prototype.updateMouse = function() {
    var k, l, len, len1, len2, m, ref, ref1, ref2, sprite;
    if (this.client.mouse.moved) {
      this.moveMouse();
    }
    if (this.client.mouse.clicked) {
      ref = this.mouseSprites;
      for (k = 0, len = ref.length; k < len; k++) {
        sprite = ref[k];
        if (sprite.mouse.click != null) {
          sprite.mouse.click.bind(sprite)(this.client.mouse.buttons);
        }
      }
    }
    if (this.client.mouse.pressed) {
      ref1 = this.mouseSprites;
      for (l = 0, len1 = ref1.length; l < len1; l++) {
        sprite = ref1[l];
        if (sprite.mouse.press != null) {
          sprite.mouse.press.bind(sprite)(this.client.mouse.buttons);
        }
      }
    }
    if (this.client.mouse.released) {
      ref2 = this.mouseSprites;
      for (m = 0, len2 = ref2.length; m < len2; m++) {
        sprite = ref2[m];
        if (sprite.mouse.release != null) {
          sprite.mouse.release.bind(sprite)(this.client.mouse.buttons);
        }
      }
    }
    this.client.mouse.moved = false;
    this.client.mouse.clicked = false;
    this.client.mouse.pressed = false;
    return this.client.mouse.released = false;
  };

  ClientGame.prototype.update = function() {
    var k, len, ref, ship;
    this.visibleSprites = [];
    ref = this.ships;
    for (k = 0, len = ref.length; k < len; k++) {
      ship = ref[k];
      ship.update();
    }
    this.interpolation.step++;
    ClientGame.__super__.update.call(this);
    return this.updateMouse();
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.drawHUD = function() {
    this.c.fillStyle = "#fff";
    this.c.font = "14px Courier New";
    this.c.fillText('x:' + this.player.ship.position[0].toFixed(0), 0, 18);
    this.c.fillText('y:' + this.player.ship.position[1].toFixed(0), 80, 18);
    this.c.fillText('r:' + this.player.ship.position[2].toFixed(2), 160, 18);
    this.c.fillText('vx:' + this.player.ship.velocity[0].toFixed(0), 260, 18);
    return this.c.fillText('vy:' + this.player.ship.velocity[1].toFixed(0), 340, 18);
  };

  ClientGame.prototype.draw = function() {
    var arrow, k, l, len, len1, ref, ref1, results, sprite;
    this.clear();
    ref = this.visibleSprites;
    for (k = 0, len = ref.length; k < len; k++) {
      sprite = ref[k];
      sprite.draw();
    }
    this.player.ship.draw();
    ref1 = this.player.arrows;
    results = [];
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      arrow = ref1[l];
      results.push(arrow.draw());
    }
    return results;
  };

  ClientGame.prototype.step = function(time) {
    ClientGame.__super__.step.call(this, time);
    return this.draw();
  };

  return ClientGame;

})(Game);
