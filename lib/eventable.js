var Config, Eventable, Util, cfg, pesoChar;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
}

pesoChar = Config.common.chars.peso;

cfg = Config.common.event;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Eventable = (function() {
  Eventable.nextID = 1;

  Eventable.registry = [];

  function Eventable(game) {
    this.game = game;
    if (!this.game) {
      return;
    }
    this.listeners = {};
    this.id = Eventable.nextID;
    this.registryIndex = (Eventable.registry.push(this)) - 1;
    Eventable.nextID++;
  }

  Eventable.prototype.getState = function() {
    return {
      id: this.id
    };
  };

  Eventable.prototype.setState = function(state) {
    var ref;
    return this.id = (ref = state.id) != null ? ref : this.id;
  };

  Eventable.prototype["delete"] = function() {
    this.events = null;
    this.listeners = null;
    return Eventable.registry.splice(this.registryIndex, 1);
  };

  Eventable.prototype.emit = function(name, data) {
    var callback, j, len, ref, ref1, results;
    if (!((ref = this.listeners[name]) != null ? ref.length : void 0)) {
      return;
    }
    ref1 = this.listeners[name];
    results = [];
    for (j = 0, len = ref1.length; j < len; j++) {
      callback = ref1[j];
      results.push(callback(data, this, this.game.tick.count));
    }
    return results;
  };

  Eventable.prototype.on = function(name, callback) {
    var ref;
    this.listeners[name] = (ref = this.listeners[name]) != null ? ref : [];
    return this.listeners[name].push(callback);
  };

  Eventable.prototype.removeListener = function(name, callback) {
    var index;
    if (!Array.isArray(this.listeners[name])) {
      return;
    }
    index = this.listeners[name].indexOf(callback);
    if (~index) {
      return this.listeners[name].splice(i, 1);
    }
  };

  Eventable.prototype.removeListeners = function(name) {
    var callbacks;
    callbacks = this.listeners[name];
    this.listeners[name] = [];
    return callbacks;
  };

  return Eventable;

})();
