var Game, Player, Server, log;

Player = require('./player');

Game = require('./game');

log = console.log;

module.exports = Server = (function() {
  function Server(io1) {
    var cb, event, ref;
    this.io = io1;
    if (!this.io) {
      return;
    }
    this.game = new Game(800, 800);
    this.game.server = this;
    ref = this.events.io;
    for (event in ref) {
      cb = ref[event];
      this.io.on(event, cb.bind(this));
    }
  }

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
          w: this.game.width,
          h: this.game.height,
          tick: this.game.tick,
          id: player.id
        });
        return log('Player', player.id, 'has joined');
      }
    },
    socket: {
      join: function(name) {
        log('Player', this.id, 'is called', name);
        this.name = name;
        return this.socket.broadcast.emit('join', {
          name: name,
          id: this.id
        });
      },
      disconnect: function() {
        log('Player', this.id, 'has left');
        io.emit('leave', this.id);
        this.game.removePlayer(this);
        if (!this.game.players.length) {
          return log('The game is empty');
        }
      },
      input: function(data) {
        if (!(this.game.server.ticks.sent && data.tick.count < this.game.server.ticks.sent.count)) {
          return this.inputs.push(data);
        }
      }
    }
  };

  return Server;

})();
