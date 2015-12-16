var Client, client, module, root;

root = typeof exports !== "undefined" && exports !== null ? exports : this;

module = module != null ? module : {};

client = null;

root.Client = module.exports = Client = (function() {
  Client.INNER_WIDTH_OFFSET = 4;

  Client.FRAME_MS = 16;

  Client.URI = 'http://localhost:3000';

  Client.COLORS = {
    BACKGROUND: {
      DEFAULT: "#444"
    }
  };

  function Client(canvas1) {
    var event;
    this.canvas = canvas1;
    if (!this.canvas) {
      return;
    }
    this.canvas.style.padding = 0;
    this.canvas.style.margin = 0;
    this.canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px';
    this.eventHandlers.resize.call(this);
    this.c = canvas.getContext('2d');
    this.g = new Game();
    for (event in this.eventHandlers) {
      window.addEventListener(event, this.eventHandlers[event]);
    }
    this.socket = io.connect(Client.URI);
    this.socket.on('init', (function(_this) {
      return function(data) {
        _this.state = data.state;
        _this.id = data.id;
        console.log('init', data.id, _this);
        return _this.frame.run.call(_this, 0);
      };
    })(this));
    this.socket.on('state', (function(_this) {
      return function(data) {
        return _this.state = data;
      };
    })(this));
    this.socket.on('newPlayer', (function(_this) {
      return function(playerID) {
        return console.log('player', playerID, 'is new');
      };
    })(this));
    this.socket.on('playerLeft', (function(_this) {
      return function(playerID) {
        var ref;
        console.log('player', playerID, 'has left');
        return (ref = _this.state.players) != null ? ref.splice(playerID - 1, 1) : void 0;
      };
    })(this));
    this.socket.on('disconnect', (function(_this) {
      return function() {
        console.log('Game over!');
        _this.frame.stop();
        return _this.socket.close();
      };
    })(this));
  }

  Client.prototype.eventHandlers = {
    keydown: function(e) {},
    keyup: function(e) {},
    mousemove: function(e) {},
    mousedown: function(e) {},
    mouseup: function(e) {},
    click: function(e) {},
    resize: function(e) {
      this.canvas.width = window.innerWidth - Client.INNER_WIDTH_OFFSET;
      this.canvas.height = window.innerHeight - Client.INNER_WIDTH_OFFSET;
      this.canvas.halfWidth = this.canvas.width >> 1;
      return this.canvas.halfHeight = this.canvas.height >> 1;
    }
  };

  Client.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  Client.prototype.update = function() {
    var i, len, player, ref, results;
    if (this.state) {
      this.g.patch(this.state);
      this.state = null;
    }
    ref = this.g.players;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      player = ref[i];
      results.push(player.update());
    }
    return results;
  };

  Client.prototype.drawPlayer = function(p) {
    if (!(p && p.ship)) {
      return;
    }
    this.c.fillStyle = p.ship.color;
    return this.c.fillRect(p.ship.position[0], p.ship.position[1], 10, 10);
  };

  Client.prototype.draw = function() {
    var i, len, p, ref, results;
    this.clear();
    ref = this.g.players;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      p = ref[i];
      results.push(this.drawPlayer(p));
    }
    return results;
  };

  Client.prototype.frame = {
    run: function(timestamp) {
      this.update();
      this.draw();
      return this.frame.request = window.requestAnimationFrame(this.frame.run.bind(this));
    },
    stop: function() {
      return window.cancelAnimationFrame(this.frame.request);
    },
    request: null
  };

  return Client;

})();

window.onload = function() {
  return client = new Client(document.querySelector('canvas'));
};

(function() {
  var i, lastTime, len, vendor, vendors;
  lastTime = 0;
  vendors = ['webkit', 'moz'];
  for (i = 0, len = vendors.length; i < len; i++) {
    vendor = vendors[i];
    if (window.requestAnimationFrame) {
      break;
    }
    window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame'];
    window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] || window[vendor + 'CancelRequestAnimationFrame'];
  }
  if (!window.requestAnimationFrame) {
    window.requestAnimationFrame = function(callback, element) {
      var currTime, id, timeToCall;
      currTime = +(new Date);
      timeToCall = Math.max(0, client.FRAME_MS - (currTime - lastTime));
      id = window.setTimeout((function() {
        return callback(currTime + timeToCall);
      }), timeToCall);
      lastTime = currTime + timeToCall;
      return id;
    };
  }
  return window.cancelAnimationFrame != null ? window.cancelAnimationFrame : window.cancelAnimationFrame = function(id) {
    return clearTimeout(id);
  };
})();
