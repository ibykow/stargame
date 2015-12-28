var Game, Player, Server, ServerGame, log;

log = console.log;

Player = require('./player');

Game = require('./game');

ServerGame = require('./servergame');

module.exports = Server = (function() {
  Server.FRAMES_PER_STEP = 5;

  Server.MAP_SIZE = (1 << 15) + 1;

  Server.startPosition = null;

  function Server(io) {
    var cb, event, ref;
    this.io = io;
    if (!this.io) {
      return;
    }
    this.game = new ServerGame(this, Server.MAP_SIZE, Server.MAP_SIZE, 4000, 0.99);
    this.frameInterval = Server.FRAMES_PER_STEP * Game.FRAME_MS;
    this.nextPlayerID = 0;
    console.log('Server frame interval:', this.frameInterval + 'ms');
    ref = this.events.io;
    for (event in ref) {
      cb = ref[event];
      this.io.on(event, cb.bind(this));
    }
  }

  Server.prototype.pause = function() {
    log('The game is empty. Pausing.');
    return this.frame.stop.bind(this)();
  };

  Server.prototype.unpause = function() {
    log('unpausing');
    return this.frame.run.bind(this)(+(new Date));
  };

  Server.prototype.events = {
    io: {
      connection: function(socket) {
        var cb, event, player, ref;
        player = new Player(this.game, this.nextPlayerID, socket);
        this.game.players.push(player);
        this.nextPlayerID++;
        ref = this.events.socket;
        for (event in ref) {
          cb = ref[event];
          socket.on(event, cb.bind(player));
        }
        socket.emit('welcome', {
          game: {
            width: this.game.width,
            height: this.game.height,
            frictionRate: this.game.frictionRate,
            tick: this.game.tick,
            starStates: this.game.starStates
          },
          id: player.id,
          ship: player.ship.getState()
        });
        return log('Player', player.id, 'has joined');
      }
    },
    socket: {
      join: function(name) {
        log('Player', this.id, 'is called', name);
        this.name = name;
        this.socket.broadcast.emit('join', {
          name: name,
          id: this.id
        });
        if (this.game.players.length === 1) {
          return this.game.server.unpause();
        }
      },
      disconnect: function() {
        log('Player', this.id, 'has left');
        this.game.server.io.emit('leave', this.id);
        this.game.removePlayer(this);
        if (!this.game.players.length) {
          return this.game.server.pause();
        }
      },
      input: function(data) {
        if (!data.sequence) {
          return;
        }
        this.inputs = data.inputs;
        this.clientState = data.ship;
        this.inputSequence = data.sequence;
        return this.update();
      }
    }
  };

  Server.prototype.frame = {
    run: function(timestamp) {
      var dt, ms;
      dt = +(new Date);
      this.game.step(timestamp);
      dt = +(new Date) - dt;
      ms = this.frameInterval - dt;
      if (ms < 10) {
        ms = 10;
      }
      return this.frame.request = setTimeout(((function(_this) {
        return function() {
          return _this.frame.run.bind(_this)(+(new Date));
        };
      })(this)), ms);
    },
    stop: function() {
      return clearTimeout(this.frame.request);
    }
  };

  return Server;

})();
