var Game, root,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

root = typeof exports !== "undefined" && exports !== null ? exports : this;

root.Game = Game = (function() {
  var GameObject, MovableObject, Player, Ship, Star;

  Game.randomColorString = function(range, base) {
    if (range == null) {
      range = 0xFFFFFF >> 2;
    }
    if (base == null) {
      base = range * 3;
    }
    return "#" + (Math.floor(Math.random() * range) + base).toString(16);
  };

  Game.isNumeric = function(v) {
    return !isNaN(parseFloat(v)) && isFinite(v);
  };

  function Game(width, height) {
    this.width = width != null ? width : 800;
    this.height = height != null ? height : 800;
    this.players = [];
    this.objects = [];
  }

  Game.prototype.randomPosition = function() {
    return [Math.floor(Math.random() * this.width), Math.floor(Math.random() * this.height)];
  };

  Game.prototype.serialize = function() {
    var i, len, player, ref, states;
    states = [];
    ref = this.players;
    for (i = 0, len = ref.length; i < len; i++) {
      player = ref[i];
      if (!!player) {
        states.push(player.serialize());
      }
    }
    return {
      w: this.width,
      h: this.height,
      states: states
    };
  };

  Game.prototype.patch = function(state) {
    var i, index, len, player, playerState, ref, ref1, ref2, results;
    this.width = (ref = state.w) != null ? ref : this.width;
    this.height = (ref1 = state.h) != null ? ref1 : this.height;
    ref2 = state.p;
    results = [];
    for (i = 0, len = ref2.length; i < len; i++) {
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
      this.position = position != null ? position : Game.randomPosition();
      this.theta = theta != null ? theta : 0;
      this.color = color != null ? color : randomColorString();
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

    function Ship(player1, arg) {
      this.player = player1;
      this.position = arg.position, this.theta = arg.theta, this.velocity = arg.velocity, this.color = arg.color;
      if (!this.player) {
        return;
      }
      Ship.__super__.constructor.call(this, this.player.game, this.position, this.theta, this.color);
    }

    Ship.prototype.serialize = function() {
      return {
        position: this.position,
        orientation: this.orientation,
        velocity: this.velocity({
          theta: this.theata,
          color: this.color
        })
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
