var ClientGame, Sprite,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./game');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = ClientGame = (function(superClass) {
  extend(ClientGame, superClass);

  function ClientGame(details, canvas, c, socket) {
    var ref;
    this.canvas = canvas;
    this.c = c;
    if (!details) {
      return;
    }
    ref = details.game, this.width = ref.width, this.height = ref.height, this.frictionRate = ref.frictionRate, this.tick = ref.tick;
    ClientGame.__super__.constructor.call(this, this.width, this.height, this.frictionRate);
    this.player = new Player(this, details.player.id, socket);
    this.player.name = 'Guest';
    this.players = [this.player];
  }

  ClientGame.prototype.update = function() {
    ClientGame.__super__.update.call(this);
    return this.draw();
  };

  ClientGame.prototype.clear = function() {
    this.c.globalAlpha = 1;
    this.c.fillStyle = Client.COLORS.BACKGROUND.DEFAULT;
    return this.c.fillRect(0, 0, this.canvas.width, this.canvas.height);
  };

  ClientGame.prototype.draw = function() {
    var i, len, player, ref, results;
    this.clear();
    ref = this.players;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      player = ref[i];
      results.push(player.ship.draw());
    }
    return results;
  };

  return ClientGame;

})(Game);
