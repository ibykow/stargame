var Client, client;

client = null;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Client = (function() {
  Client.INNER_WIDTH_OFFSET = 4;

  Client.FRAME_MS = 16;

  Client.URI = 'http://localhost:3000';

  Client.COLORS = {
    BACKGROUND: {
      DEFAULT: "#444"
    }
  };

  function Client(canvas1) {
    var cb, event, ref, ref1;
    this.canvas = canvas1;
    if (!this.canvas) {
      return;
    }
    this.canvas.style.padding = 0;
    this.canvas.style.margin = 0;
    this.canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px';
    this.events.window.resize.call(this);
    this.c = canvas.getContext('2d');
    this.g = new Game();
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
  }

  Client.prototype.events = {
    socket: {
      welcome: function(data) {
        this.game = new Game(data.w, data.h);
        this.game.tick = data.tick;
        this.player = new Player(this.game, data.id, this.socket);
        this.player.name = 'Guest';
        return this.socket.emit('join', this.player.name);
      },
      join: function(data) {
        return console.log('player', data.id + ', ' + data.name, 'has joined');
      },
      leave: function(id) {
        return console.log('player', id, 'has left');
      },
      disconnect: function() {
        console.log('Game over!');
        this.frame.stop.bind(this)();
        return this.socket.close();
      },
      state: function(data) {
        return this.state = data;
      }
    },
    window: {
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
    }
  };

  Client.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  Client.prototype.update = function() {};

  Client.prototype.draw = function() {
    return this.clear();
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
