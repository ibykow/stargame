var Client, Config, client;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
}

client = null;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Client = (function() {
  Client.INNER_WIDTH_OFFSET = 0;

  Client.INNER_HEIGHT_OFFSET = 0;

  Client.URI = 'http://192.168.0.101:3000';

  Client.COLORS = {
    BACKGROUND: {
      DEFAULT: "#000"
    }
  };

  Client.KEY = {
    SPACE: 32,
    LEFT: 37,
    RIGHT: 39,
    UP: 38,
    DOWN: 40,
    F: 'F'.charCodeAt(0)
  };

  function Client(canvas1) {
    var cb, event, ref, ref1;
    this.canvas = canvas1;
    if (!this.canvas) {
      return;
    }
    this.canvas.style.padding = 0;
    this.canvas.style.margin = 0;
    this.socket = io.connect(Client.URI);
    ref = this.events.socket;
    for (event in ref) {
      cb = ref[event];
      this.socket.on(event, cb.bind(this));
    }
    ref1 = this.events.window;
    for (event in ref1) {
      cb = ref1[event];
      window.addEventListener(event, cb.bind(this));
    }
    this.events.window.resize.call(this);
    this.keys = (function() {
      var j, results;
      results = [];
      for (j = 0; j <= 255; j++) {
        results.push(false);
      }
      return results;
    })();
    this.mouse = {
      x: 0,
      y: 0,
      buttons: [false, false, false]
    };
  }

  Client.prototype.keymap = new Array(0x100);

  Client.prototype.getMappedInputs = function() {
    var i, j, ref, results;
    results = [];
    for (i = j = 0, ref = this.keymap.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.keys[i] && this.keymap[i]) {
        results.push(this.keymap[i]);
      }
    }
    return results;
  };

  Client.prototype.events = {
    socket: {
      error: function(err) {
        return console.log("Error:", err);
      },
      welcome: function(data) {
        var context;
        context = this.canvas.getContext('2d');
        this.game = new ClientGame(data, this.canvas, context, this.socket);
        this.game.client = this;
        this.keymap[Client.KEY.UP] = 'forward';
        this.keymap[Client.KEY.DOWN] = 'reverse';
        this.keymap[Client.KEY.LEFT] = 'left';
        this.keymap[Client.KEY.RIGHT] = 'right';
        this.keymap[Client.KEY.SPACE] = 'brake';
        this.keymap[Client.KEY.F] = 'fire';
        this.socket.emit('join', this.game.player.name);
        this.game.player.ship.setState(data.ship);
        return this.game.player.ship.updateView = this.game.player.ship.updateViewMaster;
      },
      join: function(data) {
        return console.log('player', data.id + ', ' + data.name, 'has joined');
      },
      leave: function(id) {
        this.game.removeShip(id);
        return console.log('player', id, 'has left');
      },
      disconnect: function() {
        console.log('Game over!');
        this.frame.stop.bind(this)();
        return this.socket.close();
      },
      state: function(data) {
        var callback;
        if (!data.ships) {
          return;
        }
        console.log('received', data);
        callback = this.game.processServerData.bind(this.game);
        this.socket.removeAllListeners('state');
        this.socket.on('state', callback);
        callback(data);
        return this.frame.run.bind(this)(this.game.tick.time);
      }
    },
    window: {
      keydown: function(e) {
        return this.keys[e.keyCode] = true;
      },
      keyup: function(e) {
        return this.keys[e.keyCode] = false;
      },
      click: function(e) {
        return this.mouse.clicked = true;
      },
      mousedown: function(e) {
        this.mouse.pressed = true;
        return this.mouse.buttons[e.button] = true;
      },
      mouseup: function(e) {
        this.mouse.released = true;
        return this.mouse.buttons[e.button] = false;
      },
      mousemove: function(e) {
        this.mouse.moved = true;
        this.mouse.x = e.clientX - canvas.boundingRect.left;
        return this.mouse.y = e.clientY - canvas.boundingRect.top;
      },
      resize: function(e) {
        this.canvas.width = window.innerWidth - Client.INNER_WIDTH_OFFSET;
        this.canvas.height = window.innerHeight - Client.INNER_HEIGHT_OFFSET;
        this.canvas.halfWidth = this.canvas.width >> 1;
        this.canvas.halfHeight = this.canvas.height >> 1;
        return this.canvas.boundingRect = this.canvas.getBoundingClientRect();
      }
    }
  };

  Client.prototype.frame = {
    run: function(timestamp) {
      this.frame.request = window.requestAnimationFrame(this.frame.run.bind(this));
      return this.game.step(timestamp);
    },
    stop: function() {
      this.game.gameOver();
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
  var j, lastTime, len, vendor, vendors;
  lastTime = 0;
  vendors = ['webkit', 'moz'];
  for (j = 0, len = vendors.length; j < len; j++) {
    vendor = vendors[j];
    if (window.requestAnimationFrame) {
      break;
    }
    window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame'];
    window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] || window[vendor + 'CancelRequestAnimationFrame'];
  }
  if (!window.requestAnimationFrame) {
    window.requestAnimationFrame = function(callback, element) {
      var currTime, timeToCall;
      currTime = +(new Date);
      timeToCall = Math.max(0, Config.common.msPerFrame - (currTime - lastTime));
      lastTime = currTime + timeToCall;
      return window.setTimeout((function() {
        return callback(lastTime);
      }), timeToCall);
    };
  }
  return window.cancelAnimationFrame != null ? window.cancelAnimationFrame : window.cancelAnimationFrame = function(id) {
    return clearTimeout(id);
  };
})();
