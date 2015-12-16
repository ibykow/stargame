var Game,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Game = (function() {
  var GameObject, MovableObject, Player, Ship, Star;

  Game.isNumeric = function(v) {
    return !isNaN(parseFloat(v)) && isFinite(v);
  };

  Game.randomInt = function(min, max) {
    if (min == null) {
      min = 0;
    }
    if (max == null) {
      max = 99;
    }
    return Math.floor(Math.random() * (max - min) + min);
  };

  Game.padString = function(s, n, p) {
    var len;
    if (n == null) {
      n = 2;
    }
    if (p == null) {
      p = '0';
    }
    if (!(s && typeof s === 'string')) {
      return '';
    }
    len = n - s.length;
    if (len <= 0) {
      return s;
    }
    return ((function() {
      var i, ref, results;
      results = [];
      for (i = 1, ref = len; 1 <= ref ? i <= ref : i >= ref; 1 <= ref ? i++ : i--) {
        results.push(p);
      }
      return results;
    })()).join('') + s;
  };

  Game.randomColorString = function(min, max) {
    if (min == null) {
      min = 0xff >> 1;
    }
    if (max == null) {
      max = 0xff;
    }
    return '#' + Game.padString(Game.randomInt(min, max).toString(16)) + Game.padString(Game.randomInt(min, max).toString(16)) + Game.padString(Game.randomInt(min, max).toString(16));
  };

  function Game(width, height) {
    this.width = width != null ? width : 800;
    this.height = height != null ? height : 800;
    this.players = [];
    this.objects = [];
  }

  Game.prototype.randomPosition = function() {
    return [Game.randomInt(0, this.width), Game.randomInt(0, this.height)];
  };

  Game.prototype.serialize = function() {
    var i, len1, player, ref, states;
    states = [];
    ref = this.players;
    for (i = 0, len1 = ref.length; i < len1; i++) {
      player = ref[i];
      if (!!player) {
        states.push(player.serialize());
      }
    }
    return {
      width: this.width,
      height: this.height,
      players: states
    };
  };

  Game.prototype.patch = function(state) {
    var i, index, len1, player, playerState, ref, ref1, ref2, results;
    this.width = (ref = state.width) != null ? ref : this.width;
    this.height = (ref1 = state.height) != null ? ref1 : this.height;
    if (!state.players) {
      return;
    }
    ref2 = state.players;
    results = [];
    for (i = 0, len1 = ref2.length; i < len1; i++) {
      playerState = ref2[i];
      index = playerState.id - 1;
      player = this.players[index];
      if (player) {
        results.push(player.patch(playerState));
      } else {
        results.push(this.players[index] = this.playerFromState(playerState));
      }
    }
    return results;
  };

  Game.prototype.playerFromState = function(playerState) {
    var p;
    p = new Player(this, playerState.id, null, playerState.name);
    p.state = playerState;
    return p.ship = new Ship(p, playerState.ship);
  };

  Game.GameObject = GameObject = (function() {
    function GameObject(game, position, theta, color) {
      this.game = game;
      this.position = position != null ? position : this.game.randomPosition();
      this.theta = theta != null ? theta : 0;
      this.color = color != null ? color : Game.randomColorString();
    }

    return GameObject;

  })();

  Game.MovableObject = MovableObject = (function(superClass) {
    extend(MovableObject, superClass);

    function MovableObject(game, position, theta, color, velocity) {
      this.game = game;
      this.position = position;
      this.theta = theta;
      this.color = color;
      this.velocity = velocity != null ? velocity : [0, 0];
      MovableObject.__super__.constructor.call(this, this.game, this.position, this.theta, this.color);
    }

    MovableObject.prototype.accelerate = function() {
      this.velocity[0] -= this.velocity[0] * this.game.friction;
      return this.velocity[1] -= this.velocity[1] * this.game.friction;
    };

    MovableObject.prototype.updateVelocity = function() {
      return this.velocity[0] && this.velocity[1];
    };

    MovableObject.prototype.updatePosition = function() {
      this.position[0] = (this.position[0] + this.velocity[0] + this.game.width) % this.game.width;
      return this.position[1] = (this.position[1] - this.velocity[1] + this.game.height) % this.game.height;
    };

    MovableObject.prototype.update = function() {
      this.accelerate();
      if (this.updateVelocity()) {
        return this.updatePosition();
      }
    };

    return MovableObject;

  })(Game.GameObject);

  Game.Star = Star = (function(superClass) {
    extend(Star, superClass);

    Star.MAX_SIZE = 30;

    function Star(game) {
      this.game = game;
      Star.__super__.constructor.call(this, this.game);
      this.size = Math.floor(Math.random() * Star.MAX_SIZE);
    }

    return Star;

  })(MovableObject);

  Game.Player = Player = (function() {
    function Player(game, id, socket, name) {
      this.game = game;
      this.id = id;
      this.socket = socket;
      this.name = name != null ? name : 'Bob';
      if (!(this.game && this.id)) {
        return;
      }
      this.ship = new Ship(this, {});
      this.keys = (function() {
        var i, results;
        results = [];
        for (i = 1; i <= 255; i++) {
          results.push(false);
        }
        return results;
      })();
    }

    Player.prototype.serialize = function() {
      var ref;
      return {
        id: this.id,
        name: this.name,
        ship: (ref = this.ship) != null ? ref.serialize() : void 0
      };
    };

    Player.prototype.patch = function(state) {
      var ref;
      this.color = (ref = state.color) != null ? ref : this.color;
      if (state.ship) {
        return this.ship.patch(state.ship);
      }
    };

    return Player;

  })();

  Game.Ship = Ship = (function(superClass) {
    extend(Ship, superClass);

    function Ship(player1, state) {
      this.player = player1;
      if (state == null) {
        state = {
          position: this.position,
          theta: this.theta,
          velocity: this.velocity,
          color: this.color
        };
      }
      if (!(this.player && state)) {
        return;
      }
      Ship.__super__.constructor.call(this, this.player.game, this.position, this.theta, this.color);
    }

    Ship.prototype.serialize = function() {
      return {
        position: this.position,
        orientation: this.orientation,
        velocity: this.velocity,
        theta: this.theta,
        color: this.color
      };
    };

    Ship.prototype.patch = function(state) {
      var key;
      for (key in state) {
        this[key] = state[key];
      }
      return this.position = state.position;
    };

    return Ship;

  })(MovableObject);

  return Game;

})();
