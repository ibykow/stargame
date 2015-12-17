var Frame, Tick, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

if (typeof require !== "undefined" && require !== null) {
  Tick = require('./tick');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Frame = (function() {
  function Frame(game, time, previousFrame, inputs) {
    this.game = game;
    if (time == null) {
      time = 0;
    }
    if (previousFrame == null) {
      previousFrame = {};
    }
    this.inputs = inputs != null ? inputs : [];
    if (!this.game) {
      return;
    }
    this.tick = new Tick(time, previousFrame.tick);
    this.state = {
      width: this.game.width,
      height: this.game.height,
      players: [],
      sprites: []
    };
  }

  return Frame;

})();
