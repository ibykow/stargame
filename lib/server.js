var Game, Player, Server, log;

Player = require('./player');

Game = require('./servergame');

log = console.log;

module.exports = Server = (function() {
  Server.FRAME_INTERVAL = 16;

  function Server(io) {
    var cb, event, ref;
    this.io = io;
    if (!this.io) {
      return;
    }
    this.game = new Game(this, 1024, 600, 10);
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
        player = this.game.newPlayer(socket);
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
            states: this.game.states
          },
          player: {
            id: player.id
          }
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
        return this.input.push(data);
      }
    }
  };

  Server.prototype.frame = {
    run: function(timestamp) {
      var ms;
      this.game.step(timestamp);
      ms = Server.FRAME_INTERVAL;
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
