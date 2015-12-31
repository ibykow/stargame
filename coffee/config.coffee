# Provide configuration data
(module ? {}).exports = Config =
  client:
    innerWidthOffset: 0
    innerHeightOffset: 0
    colors:
      background:
        default: '#000'
    keyCodes:
      space: 32
      left: 37
      right: 39
      up: 38
      down: 40
      f: 'F'.charCodeAt 0
    player:
      loglen: 1 << 8
    pager:
      color: '#0f0'
      fade: 30
      font: '12px Courier New'
      maxlines: 20
      ttl: 60 * 3
      xoffset: 10
      yoffset: 12

  server:
    updatesPerStep: 5

  common:
    uri: 'http://localhost:3000'
    msPerFrame: 16
    mapSize: (1 << 15) + 1
    chars:
      peso: '\u03df'
    rates:
      gasStations: 0.3 # probability of a star having a gas station
    fuel:
      price:
        min: 0.8
        max: 1.9
    bullet:
      life: 60 * 3
      speed: 10
    button:
      width: 50
      height: 50
      offset: [0, -8, 0]
      colors:
        background: '#666'
        hover: '#888'
        click: '#444'
        text: '#fff'
      font:
        string: '12px Courier New'
        offset: [10, 4, 0]
      default:
        enabled: true
    ringbuffer:
      max: 50
    ship:
      rates:
        acceleration: 2
        brake: 0.96
        fire: 4
        turn: 0.06
