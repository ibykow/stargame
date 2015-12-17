var Player;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Player = (function() {
  function Player(game, id, socket) {
    this.game = game;
    this.id = id;
    this.socket = socket;
    if (!(this.game && this.id)) {
      return null;
    }
    this.inputs = [];
  }

  Player.prototype.processInputs = function() {};

  Player.prototype.updateVelocity = function() {};

  Player.prototype.updateView = function() {};

  Player.prototype.update = function() {
    this.processInputs();
    this.updateVelocity();
    return this.updateView();
  };

  return Player;

})();
