var Frame, Game, Util;

if (typeof require !== "undefined" && require !== null) {
  Util = require('./util');
}

if (typeof require !== "undefined" && require !== null) {
  Game = require('./game');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Frame = (function() {
  function Frame(game, time, input, tick, state) {
    this.game = game;
    this.time = time != null ? time : 0;
    this.input = input != null ? input : [];
    this.tick = tick != null ? tick : 0;
    this.state = state != null ? state : {};
    this.dt = 0;
  }

  return Frame;

})();
