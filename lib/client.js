var Client, client;

client = null;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Client = (function() {
  Client.INNER_WIDTH_OFFSET = 4;

  Client.FRAME_MS = 16;

  Client.URI = 'http://192.168.0.101:3000';

  Client.COLORS = {
    BACKGROUND: {
      DEFAULT: "#444"
    }
  };

  function Client(canvas) {
    var cb, event, ref;
    this.canvas = canvas;
    if (!this.canvas) {
      return;
    }
    this.canvas.style.padding = 0;
    this.canvas.style.margin = 0;
    this.canvas.style.left = (Client.INNER_WIDTH_OFFSET >> 1) + 'px';
    this.events.window.resize.call(this);
    this.socket = io.connect(Client.URI);
    ref = this.events.socket;
    for (event in ref) {
      cb = ref[event];
      this.socket.on(event, cb.bind(this));
    }
  }

  Client.prototype.events = {
    socket: {
      welcome: function(data) {
        var addListener, cb, context, event, ref, results;
        context = this.canvas.getContext('2d');
        this.game = new ClientGame(data, this.canvas, context, data.player.id);
        this.socket.emit('join', this.game.player.name);
        this.frame.run.bind(this)(this.game.tick.time);
        addListener = window.addEventListener;
        ref = this.events.window;
        results = [];
        for (event in ref) {
          cb = ref[event];
          results.push(addListener(event, cb.bind(this)));
        }
        return results;
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

  Client.prototype.frame = {
    run: function(timestamp) {
      this.game.step(timestamp);
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
      var currTime, timeToCall;
      currTime = +(new Date);
      timeToCall = Math.max(0, client.FRAME_MS - (currTime - lastTime));
      lastTime = currTime + timeToCall;
      return window.setTimeout((function() {
        return callback(currTime + timeToCall);
      }), timeToCall);
    };
  }
  return window.cancelAnimationFrame != null ? window.cancelAnimationFrame : window.cancelAnimationFrame = function(id) {
    return clearTimeout(id);
  };
})();
