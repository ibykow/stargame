var Tick;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Tick = (function() {
  function Tick(time, previousTick) {
    this.time = time != null ? time : 0;
    if (previousTick == null) {
      previousTick = {
        count: 0,
        time: 0
      };
    }
    this.count = previousTick.count + 1;
    this.dt = this.time - previousTick.time;
  }

  return Tick;

})();
