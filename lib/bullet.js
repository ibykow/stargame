var Bullet, Config, Sprite, Util, ceil, cos, life, nextBulletID, ref, ref1, sin, speed,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof require !== "undefined" && require !== null) {
  Config = require('./config');
  Util = require('./util');
  Sprite = require('./sprite');
}

ref = [Math.ceil, Math.cos, Math.sin], ceil = ref[0], cos = ref[1], sin = ref[2];

ref1 = Config.common.bullet, speed = ref1.speed, life = ref1.life;

nextBulletID = 1;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Bullet = (function(superClass) {
  extend(Bullet, superClass);

  Bullet.fromState = function(game, state) {
    var b;
    if (!(game && state)) {
      return;
    }
    state.gun.game = game;
    b = new Bullet(state.gun);
    b.setState(state);
    return b;
  };

  function Bullet(gun, damage) {
    var vx, vy, xdir, xnorm, ydir, ynorm;
    this.gun = gun;
    this.damage = damage != null ? damage : 2;
    if (!this.gun) {
      return;
    }
    Bullet.__super__.constructor.call(this, this.gun.game, this.gun.position.slice(), 2, 2, "#ffd");
    vx = this.gun.velocity[0];
    vy = this.gun.velocity[1];
    xdir = cos(this.position[2]);
    ydir = sin(this.position[2]);
    xnorm = ceil(xdir);
    ynorm = ceil(ydir);
    this.velocity = [xdir * speed, ydir * speed];
    this.position[0] += xdir * (this.gun.width + 2);
    this.position[1] += ydir * (this.gun.height + 2);
    this.life = life;
    this.id = nextBulletID;
    nextBulletID++;
  }

  Bullet.prototype.getState = function() {
    var state;
    state = Bullet.__super__.getState.call(this);
    state.life = this.life;
    state.damage = this.damage;
    state.id = this.id;
    state.gun = this.gun.getState();
    state.gun.player = {
      id: this.gun.player.id
    };
    return state;
  };

  Bullet.prototype.setState = function(state) {
    var ref2, ref3, ref4, ref5;
    Bullet.__super__.setState.call(this, state);
    this.life = (ref2 = state.life) != null ? ref2 : this.life;
    this.damage = (ref3 = state.damage) != null ? ref3 : this.damage;
    this.id = (ref4 = state.id) != null ? ref4 : this.id;
    return this.gun.player = {
      id: (ref5 = state.gun.player.id) != null ? ref5 : this.gun.player.id
    };
  };

  Bullet.prototype.updateVelocity = function() {};

  Bullet.prototype.update = function() {
    Bullet.__super__.update.call(this);
    return this.life--;
  };

  return Bullet;

})(Sprite);
