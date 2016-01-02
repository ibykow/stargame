var Config;

(typeof module !== "undefined" && module !== null ? module : {}).exports = Config = {
  client: {
    colors: {
      background: {
        "default": '#000'
      }
    },
    innerWidthOffset: 0,
    innerHeightOffset: 0,
    keys: {
      space: {
        code: 32,
        action: 'brake'
      },
      left: {
        code: 37,
        action: 'left'
      },
      right: {
        code: 39,
        action: 'right'
      },
      up: {
        code: 38,
        action: 'forward'
      },
      down: {
        code: 40,
        action: 'reverse'
      },
      f: {
        code: 'F'.charCodeAt(0),
        action: 'fire'
      }
    },
    pager: {
      color: '#0f0',
      fade: 30,
      font: '12px Courier New',
      maxlines: 20,
      ttl: 60 * 8,
      xoffset: 10,
      yoffset: 12
    },
    player: {
      loglen: 1 << 8
    }
  },
  server: {
    updatesPerStep: 5
  },
  common: {
    uri: 'http://localhost:3000',
    bullet: {
      life: 60 * 3,
      speed: 10
    },
    button: {
      width: 50,
      height: 50,
      offset: [0, -8, 0],
      colors: {
        background: '#666',
        hover: '#888',
        click: '#444',
        text: '#fff'
      },
      font: {
        string: '12px Courier New',
        offset: [10, 4, 0]
      },
      "default": {
        enabled: true
      }
    },
    chars: {
      peso: '\u03df'
    },
    event: {
      max: 0x100
    },
    fuel: {
      distance: 50,
      price: {
        min: 0.8,
        max: 1.9
      }
    },
    mapSize: (1 << 15) + 1,
    msPerFrame: 16,
    rates: {
      gasStation: 0.1
    },
    ringbuffer: {
      max: 50
    },
    ship: {
      rates: {
        acceleration: 2,
        brake: 0.96,
        fire: 4,
        turn: 0.06
      }
    }
  }
};
