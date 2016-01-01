# Provide configuration data
(module ? {}).exports = Config =
  client:
    innerWidthOffset: 0
    innerHeightOffset: 0
    colors:
      background:
        default: '#000'
    keys:
      space:
        code: 32
        action: 'brake'
      left:
        code: 37
        action: 'left'
      right:
        code: 39
        action: 'right'
      up:
        code: 38
        action: 'forward'
      down:
        code: 40
        action: 'reverse'
      f:
        code: 'F'.charCodeAt 0
        action: 'fire'
    player:
      loglen: 1 << 8
    pager:
      color: '#0f0'
      fade: 30
      font: '12px Courier New'
      maxlines: 20
      ttl: 60 * 8
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
      gasStation: 0.1 # probability of a star having a gas station
    fuel:
      distance: 50 # max refueling distance
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
