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

  server:
    updatesPerStep: 5

  common:
    uri: 'http://localhost:3000'
    msPerFrame: 16
    mapSize: (1 << 15) + 1
    bullet:
      life: 60
      speed: 10
    ship:
      rates:
        acceleration: 2
        brake: 0.96
        turn: 0.06
