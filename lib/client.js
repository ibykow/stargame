var Client, client;

client = null;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Client = (function() {
  Client.INNER_WIDTH_OFFSET = 4;

  Client.FRAME_MS = 16;

  Client.URI = 'http://192.168.0.101:3000';

  Client.COLORS = {
    BACKGROUND: {
      DEFAULT: "#000"
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

  Client.prototype.generateInput = function() {
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
      welcome: function(data) {
        var context;
        context = this.canvas.getContext('2d');
        this.game = new ClientGame(data, this.canvas, context, data.player.id);
        this.keymap[32] = 'brake';
        this.keymap[37] = 'left';
        this.keymap[38] = 'forward';
        this.keymap[39] = 'right';
        this.keymap[40] = 'reverse';
        this.socket.emit('join', this.game.player.name);
        return this.frame.run.bind(this)(this.game.tick.time);
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
        if (!(this.game.state.tick.count > data.tick.count)) {
          return this.game.state = data;
        }
      }
    },
    window: {
      keydown: function(e) {
        return this.keys[e.keyCode] = true;
      },
      keyup: function(e) {
        return this.keys[e.keyCode] = false;
      },
      mousemove: function(e) {
        this.mouse.x = e.clientX - canvas.boundingRect.left;
        return this.mouse.y = e.clientY - canvas.boundingRect.top;
      },
      mousedown: function(e) {
        return this.mouse.buttons[e.button] = true;
      },
      mouseup: function(e) {
        return this.mouse.buttons[e.button] = false;
      },
      click: function(e) {},
      resize: function(e) {
        this.canvas.width = window.innerWidth - Client.INNER_WIDTH_OFFSET;
        this.canvas.height = window.innerHeight - Client.INNER_WIDTH_OFFSET;
        this.canvas.halfWidth = this.canvas.width >> 1;
        this.canvas.halfHeight = this.canvas.height >> 1;
        return this.canvas.boundingRect = this.canvas.getBoundingClientRect();
      }
    }
  };

  Client.prototype.frame = {
    run: function(timestamp) {
      var input, inputLogEntry;
      input = this.game.player.input = this.generateInput();
      this.game.processState();
      this.game.step(timestamp);
      inputLogEntry = {
        tick: this.game.tick,
        input: input
      };
      if (input.length) {
        this.socket.emit('input', inputLogEntry);
      }
      this.game.inputs.push(inputLogEntry);
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
