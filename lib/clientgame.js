var Client, ClientGame, Eventable, Game, GasStation, Pager, Player, Ship, Sprite, floor, global, isarr, max, pesoChar, ref,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

global = global || window;

if (typeof require !== "undefined" && require !== null) {
  Eventable = require('./eventable');
  Sprite = require('./sprite');
  GasStation = require('./gasstation');
  Ship = require('./ship');
  Game = require('./game');
  Player = require('./player');
  Client = require('./client');
  Pager = require('./pager');
}

ref = [Array.isArray, Math.floor, Math.max], isarr = ref[0], floor = ref[1], max = ref[2];

pesoChar = Config.common.chars.peso;

Player.prototype.die = function() {
  return this.ship.isDeleted = true;
};

Sprite.updatePosition = function() {};

Sprite.updateVelocity = function() {};

(typeof module !== "undefined" && module !== null ? module : {}).exports = ClientGame = (function(superClass) {
  extend(ClientGame, superClass);

  ClientGame.events = {
    player: {
      forward: function() {
        return console.log("We're flying");
      }
    }
  };

  function ClientGame(canvas, socket, params) {
    var callback, event, name, ref1, type;
    this.canvas = canvas;
    if (!params) {
      return;
    }
    ClientGame.__super__.constructor.call(this, params.game.width, params.game.height, params.game.frictionRate);
    this.c = this.canvas.getContext('2d');
    this.starStates = params.game.starStates;
    this.serverTick = params.game.tick;
    this.visibleSprites = [];
    this.mouseSprites = [];
    this.collisionSpriteLists.stars = this.stars = this.generateStars();
    this.player = new Player(this, socket);
    this.player.id = params.id;
    this.player.name = 'Guest';
    this.lastVerifiedInputSequence = 0;
    this.collisionSpriteLists.myShip = [this.player.ship];
    this.pager = new Pager(this);
    this.page = this.pager.page.bind(this.pager);
    ref1 = ClientGame.events;
    for (type in ref1) {
      event = ref1[type];
      for (name in event) {
        callback = event[name];
        this.player.on(name, callback);
      }
    }
  }

  ClientGame.prototype.interpolation = {
    reset: function() {
      this.step = 0;
      return this.rate = 1 / Config.server.updatesPerStep;
    }
  };

  ClientGame.prototype.testPager = function() {
    var i, k;
    for (i = k = 1; k <= 20; i = ++k) {
      this.pager.page('Hello, World Number ' + i);
    }
    return console.log(this.pager.buffer);
  };

  ClientGame.prototype.generateStars = function() {
    var childState, i, k, len, ref1, ref2, results, s, state, type;
    ref1 = this.starStates;
    results = [];
    for (i = k = 0, len = ref1.length; k < len; i = ++k) {
      state = ref1[i];
      s = new Sprite(this, state.position, state.width, state.height, state.color);
      s.id = i;
      ref2 = state.children;
      for (type in ref2) {
        childState = ref2[type];
        global[type].fromState(s, childState);
      }
      results.push(s);
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
    var clientPosition, count, entries, entry, inputLog, k, len, logEntry, ref1, results, serverInputSequence, serverPosition, serverState, serverStep;
    inputLog = this.player.logs['input'];
    serverInputSequence = (ref1 = this.shipState) != null ? ref1.inputSequence : void 0;
    serverState = this.shipState.ship;
    if (!(serverInputSequence > this.lastVerifiedInputSequence)) {
      return;
    }
    this.lastVerifiedInputSequence = serverInputSequence;
    serverStep = this.serverTick.count;
    inputLog.purge(function(entry) {
      return entry.sequence < serverInputSequence;
    });
    logEntry = inputLog.remove();
    if (logEntry == null) {
      return this.player.ship.setState(serverState);
    }
    clientPosition = logEntry.ship.position;
    serverPosition = serverState.position;
    if (serverState.health < logEntry.ship.health) {
      this.player.ship.health = serverState.health;
    }
    if (serverState.fuel < logEntry.ship.fuel) {
      this.player.ship.health = serverState.fuel;
    }
    if (!Util.vectorDeltaExists(clientPosition, serverPosition)) {
      return;
    }
    this.player.ship.setState(serverState);
    entries = inputLog.toArray().slice();
    inputLog.reset();
    count = this.tick.count;
    this.tick.count = logEntry.gameStep;
    results = [];
    for (k = 0, len = entries.length; k < len; k++) {
      entry = entries[k];
      console.log(entry.sequence, entry.gameStep, entry.ship.position);
      this.player.inputSequence = entry.sequence;
      this.player.inputs = entry.inputs;
      this.player.update();
      this.player.updateInputLog();
      results.push(this.tick.count++);
    }
    return results;
  };

  ClientGame.prototype.processBulletData = function(data) {
    var bullet, id;
    return this.bullets = (this.bullets.filter(function(b) {
      return data.deadBulletIDs.indexOf(b.id) === -1;
    })).concat((function() {
      var k, len, ref1, results;
      ref1 = data.bullets;
      results = [];
      for (k = 0, len = ref1.length; k < len; k++) {
        bullet = ref1[k];
        id = bullet.gun.player.id;
        if (id === this.player.id) {
          continue;
        }
        results.push(Bullet.fromState(this, bullet));
      }
      return results;
    }).call(this));
  };

  ClientGame.prototype.processServerData = function(data) {
    var i, inserted, j, k, l, p, ref1, ref2, ref3, ref4, ship, state, stateLog;
    ref1 = [false, 0, 0, this.player.logs['state']], inserted = ref1[0], i = ref1[1], j = ref1[2], stateLog = ref1[3];
    this.serverTick = data.game.tick;
    if (this.serverTick.count > this.tick.count) {
      this.tick.count = this.serverTick.count + 1;
    }
    this.processBulletData(data);
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
        this.player.arrowTo(ship, ship.player.id);
      }
    }
    if (inserted) {
      this.ships.sort(function(a, b) {
        return a.id - b.id;
      });
    }
    return this.interpolation.reset();
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
    this.client.mouse.moved = false;
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
    this.client.mouse.clicked = false;
    this.client.mouse.pressed = false;
    return this.client.mouse.released = false;
  };

  ClientGame.prototype.update = function() {
    var k, l, len, len1, ref1, ref2, ship, star;
    this.player.inputs = this.client.getKeyboardInputs();
    ClientGame.__super__.update.call(this);
    ref1 = this.stars;
    for (k = 0, len = ref1.length; k < len; k++) {
      star = ref1[k];
      star.update();
    }
    ref2 = this.ships;
    for (l = 0, len1 = ref2.length; l < len1; l++) {
      ship = ref2[l];
      ship.update();
    }
    this.updateMouse();
    this.interpolation.step++;
    this.correctPrediction();
    this.player.update();
    return this.player.updateArrows();
  };

  ClientGame.prototype.clearScreen = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Config.client.colors.background["default"];
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.drawHUD = function() {
    this.c.fillStyle = "#fff";
    this.c.font = "14px Courier New";
    this.c.fillText(this.player.ship.position[0].toFixed(0), 0, 10);
    this.c.fillText(this.player.ship.position[1].toFixed(0), 60, 10);
    this.c.fillText(this.client.mouse.x.toFixed(0), 0, 20);
    this.c.fillText(this.client.mouse.y.toFixed(0), 60, 20);
    this.c.fillText(this.player.ship.position[2].toFixed(2), 120, 10);
    this.c.fillText(this.player.ship.velocity[0].toFixed(0), 180, 10);
    this.c.fillText(this.player.ship.velocity[1].toFixed(0), 220, 10);
    this.c.fillText(pesoChar + this.player.cash.toFixed(2), 260, 10);
    return this.player.ship.drawHUD(0, 24);
  };

  ClientGame.prototype.draw = function() {
    var arrow, k, l, len, len1, ref1, ref2, sprite;
    this.clearScreen();
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
    this.drawHUD();
    return this.pager.draw();
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
    ClientGame.__super__.step.call(this, time);
    this.notifyServer();
    this.draw();
    this.player.inputs = [];
    return this.visibleSprites = [];
  };

  return ClientGame;

})(Game);
