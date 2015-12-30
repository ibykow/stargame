var Client, ClientGame, Game, Player, Ship, Sprite, floor, isarr, max, pesoChar, ref,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
  Ship = require('./ship');
  Game = require('./game');
  Player = require('./player');
  Client = require('./client');
}

ref = [Array.isArray, Math.floor, Math.max], isarr = ref[0], floor = ref[1], max = ref[2];

pesoChar = '\u03df';

Player.prototype.die = function() {
  return this.ship.isDeleted = true;
};

(typeof module !== "undefined" && module !== null ? module : {}).exports = ClientGame = (function(superClass) {
  extend(ClientGame, superClass);

  function ClientGame(details, canvas, c, socket) {
    var ref1;
    this.canvas = canvas;
    this.c = c;
    if (!details) {
      return;
    }
    ClientGame.__super__.constructor.call(this, details.game.width, details.game.height, details.game.frictionRate);
    ref1 = details.game, this.tick = ref1.tick, this.starStates = ref1.starStates;
    this.visibleSprites = [];
    this.mouseSprites = [];
    this.collisionSpriteLists.stars = this.stars = this.generateStars();
    this.player = new Player(this, details.id, socket);
    this.player.name = 'Guest';
    this.players = [this.player];
    this.lastVerifiedInputSequence = 0;
    this.collisionSpriteLists.myShip = [this.player.ship];
  }

  ClientGame.prototype.interpolation = {
    reset: function(dt) {
      this.step = 0;
      return this.rate = Config.common.msPerFrame / dt;
    }
  };

  ClientGame.prototype.generateStars = function() {
    var k, len, ref1, results, state;
    ref1 = this.starStates;
    results = [];
    for (k = 0, len = ref1.length; k < len; k++) {
      state = ref1[k];
      results.push(new Sprite(this, state.position, state.width, state.height, state.color));
    }
    return results;
  };

  ClientGame.prototype.removeShip = function(id) {
    var i, k, ref1, results;
    results = [];
    for (i = k = 0, ref1 = this.ships.length; 0 <= ref1 ? k < ref1 : k > ref1; i = 0 <= ref1 ? ++k : --k) {
      if (this.ships[i].player.id === id) {
        this.ships[i].flags.isDeleted = true;
        this.ships.splice(i, 1);
        break;
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  ClientGame.prototype.correctPrediction = function() {
    var clientPosition, entries, entry, inputLog, k, len, logEntry, ref1, results, serverInputSequence, serverPosition, serverState;
    inputLog = this.player.logs['input'];
    serverInputSequence = (ref1 = this.shipState) != null ? ref1.inputSequence : void 0;
    serverState = this.shipState.ship;
    if (!(serverInputSequence > this.lastVerifiedInputSequence)) {
      return;
    }
    this.lastVerifiedInputSequence = serverInputSequence;
    this.player.ship.health = serverState.health;
    inputLog.purge(function(entry) {
      return entry.sequence <= serverInputSequence;
    });
    logEntry = inputLog.remove();
    clientPosition = logEntry != null ? logEntry.ship.position : void 0;
    serverPosition = serverState.position;
    if (serverState.health < (logEntry != null ? logEntry.ship.health : void 0)) {
      this.player.ship.health = serverState.health;
    }
    if (!Util.vectorDeltaExists(clientPosition, serverPosition)) {
      return;
    }
    this.player.ship.setState(serverState);
    entries = inputLog.toArray().slice();
    inputLog.reset();
    results = [];
    for (k = 0, len = entries.length; k < len; k++) {
      entry = entries[k];
      this.player.inputSequence = entry.sequence;
      this.player.inputs = entry.inputs;
      results.push(this.player.update());
    }
    return results;
  };

  ClientGame.prototype.processServerData = function(data) {
    var arrow, bullet, i, inserted, j, k, l, p, ref1, ref2, ref3, ref4, ship, state, stateLog;
    ref1 = [false, 0, 0, this.player.logs['state']], inserted = ref1[0], i = ref1[1], j = ref1[2], stateLog = ref1[3];
    this.bullets = (function() {
      var k, len, ref2, results;
      ref2 = data.bullets;
      results = [];
      for (k = 0, len = ref2.length; k < len; k++) {
        bullet = ref2[k];
        results.push(Bullet.fromState(this, bullet));
      }
      return results;
    }).call(this);
    for (i = k = 0, ref2 = data.ships.length; 0 <= ref2 ? k < ref2 : k > ref2; i = 0 <= ref2 ? ++k : --k) {
      if (data.ships[i].id === this.player.id) {
        this.shipState = data.ships.splice(i, 1)[0];
        break;
      }
    }
    i = 0;
    while (i < data.ships.length && j < this.ships.length) {
      state = data.ships[i];
      ship = this.ships[j];
      if (state.id === ship.player.id) {
        ship.setState(state.ship);
      } else if (state.id > ship.player.id) {
        this.ships.splice(j, 1);
        continue;
      } else {
        p = {
          id: state.id,
          game: this
        };
        this.ships.push(new InterpolatedShip(p, state.ship));
        this.collisionSpriteLists.ships = this.ships;
        inserted = true;
      }
      i++;
      j++;
    }
    if (j > i) {
      this.ships.length = i;
    } else {
      for (j = l = ref3 = i, ref4 = data.ships.length; ref3 <= ref4 ? l < ref4 : l > ref4; j = ref3 <= ref4 ? ++l : --l) {
        state = data.ships[j];
        p = {
          id: state.id,
          game: this
        };
        this.ships.push(new InterpolatedShip(p, state.ship));
        this.collisionSpriteLists.ships = this.ships;
      }
      if (i === 0 && j > 0) {
        ship = this.ships[0];
        console.log('arrow to', ship);
        arrow = new Arrow(this, this.player.ship, ship, "#00f", 0.8, 2, ship.player.id);
        this.player.arrows.push(arrow);
      }
    }
    if (inserted) {
      this.ships.sort(function(a, b) {
        return a.id - b.id;
      });
    }
    stateLog.purge(function(entry) {
      return entry.sequence < data.tick.count;
    });
    return this.interpolation.reset(data.tick.dt);
  };

  ClientGame.prototype.isMouseInBounds = function(bounds) {
    return Util.isInSquareBounds([this.client.mouse.x, this.client.mouse.y], bounds);
  };

  ClientGame.prototype.moveMouse = function() {
    var k, l, len, len1, prevSprites, ref1, results, sprite;
    prevSprites = this.mouseSprites;
    this.mouseSprites = [];
    ref1 = this.visibleSprites;
    for (k = 0, len = ref1.length; k < len; k++) {
      sprite = ref1[k];
      if (!this.isMouseInBounds(sprite.getViewBounds())) {
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
    var k, l, len, len1, len2, m, ref1, ref2, ref3, sprite;
    if (this.client.mouse.moved) {
      this.moveMouse();
    }
    if (this.client.mouse.clicked) {
      ref1 = this.mouseSprites;
      for (k = 0, len = ref1.length; k < len; k++) {
        sprite = ref1[k];
        if (sprite.mouse.click != null) {
          sprite.mouse.click.bind(sprite)(this.client.mouse.buttons);
        }
      }
    }
    if (this.client.mouse.pressed) {
      ref2 = this.mouseSprites;
      for (l = 0, len1 = ref2.length; l < len1; l++) {
        sprite = ref2[l];
        if (sprite.mouse.press != null) {
          sprite.mouse.press.bind(sprite)(this.client.mouse.buttons);
        }
      }
    }
    if (this.client.mouse.released) {
      ref3 = this.mouseSprites;
      for (m = 0, len2 = ref3.length; m < len2; m++) {
        sprite = ref3[m];
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
    var k, l, len, len1, ref1, ref2, ship, star;
    this.visibleSprites = [];
    ClientGame.__super__.update.call(this);
    ref1 = this.stars;
    for (k = 0, len = ref1.length; k < len; k++) {
      star = ref1[k];
      star.updateView();
    }
    ref2 = this.ships;
    for (l = 0, len1 = ref2.length; l < len1; l++) {
      ship = ref2[l];
      ship.update();
    }
    this.interpolation.step++;
    this.correctPrediction();
    this.player.update();
    this.player.updateArrows();
    return this.updateMouse();
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Config.client.colors.background["default"];
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.drawFuel = function(x, y) {
    var redness, remain;
    if (!this.player.ship.fuel) {
      this.c.fillStyle = "#f00";
      this.c.font = "Bold 12px Courier";
      this.c.fillText("NO GAS", x, y + 10);
      return;
    }
    remain = this.player.ship.fuel / this.player.ship.fuelCapacity;
    redness = floor(remain * 0xFF);
    this.c.fillStyle = "rgba(" + (0xFF - redness) + "," + redness + "," + 0 + ",1)";
    this.c.strokeStyle = "#fff";
    this.c.lineWidth = 2;
    this.c.fillRect(x, y, floor(remain * 30), 9);
    return this.c.strokeRect(x, y, 30, 9);
  };

  ClientGame.prototype.drawHUD = function() {
    this.c.fillStyle = "#fff";
    this.c.font = "14px Courier New";
    this.c.fillText('x:' + this.player.ship.position[0].toFixed(0), 0, 18);
    this.c.fillText('y:' + this.player.ship.position[1].toFixed(0), 80, 18);
    this.c.fillText('r:' + this.player.ship.position[2].toFixed(2), 160, 18);
    this.c.fillText('vx:' + this.player.ship.velocity[0].toFixed(0), 260, 18);
    this.c.fillText('vy:' + this.player.ship.velocity[1].toFixed(0), 340, 18);
    this.c.fillText('hp:' + this.player.ship.health, 420, 18);
    this.c.fillText('cash:' + pesoChar + this.player.cash.toFixed(2), 540, 18);
    return this.drawFuel(480, 8);
  };

  ClientGame.prototype.draw = function() {
    var arrow, k, l, len, len1, ref1, ref2, sprite;
    this.clear();
    ref1 = this.visibleSprites;
    for (k = 0, len = ref1.length; k < len; k++) {
      sprite = ref1[k];
      sprite.draw();
    }
    this.player.ship.draw();
    ref2 = this.player.arrows;
    for (l = 0, len1 = ref2.length; l < len1; l++) {
      arrow = ref2[l];
      arrow.draw();
    }
    return this.drawHUD();
  };

  ClientGame.prototype.gameOver = function() {
    console.log('Game over!');
    this.player.ship.isDeleted = true;
    this.c.fillStyle = "#fff";
    this.c.font = '30px Helvetica';
    this.c.fillText('Game Over!', this.canvas.halfWidth - 80, this.canvas.halfHeight - 80);
    this.c.font = '14px Courier New';
    this.c.fillText("Alright, that's it! I'm sick of it!", this.canvas.halfWidth - 135, this.canvas.halfHeight - 60);
    return this.c.fillText("Shut the fuck up, I've got a gun!", this.canvas.halfWidth - 130, this.canvas.halfHeight - 42);
  };

  ClientGame.prototype.notifyServer = function() {
    var entry;
    this.player.updateInputLog();
    entry = this.player.latestInputLogEntry;
    return this.player.socket.emit('input', entry);
  };

  ClientGame.prototype.step = function(time) {
    this.player.inputs = this.client.getMappedInputs();
    this.notifyServer();
    ClientGame.__super__.step.call(this, time);
    return this.draw();
  };

  return ClientGame;

})(Game);
