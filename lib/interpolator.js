var Game, Interpolator, Ship, Sprite;

if (typeof require !== "undefined" && require !== null) {
  Sprite = require('./sprite');
  Ship = require('./ship');
  Game = require('./game');
  Game = require('./clientgame');
}

(typeof module !== "undefined" && module !== null ? module : {}).exports = Interpolator = (function() {
  var class1;

  function Interpolator() {
    return class1.apply(this, arguments);
  }

  class1 = Interpolator.game;

  return Interpolator;

})();
