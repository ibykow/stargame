# Provide configuration data
(module ? {}).exports = Config =
  benchmark: history: cutoff: 10000
  client:
    arrow:
      color: '#0F0'
      lineWidth: 0.5
    colors:
      background:
        default: '#000'
    contextMenu:
      sensor:
        alpha: 0.8
        dimensions: [10, 0]
    innerWidthOffset: 0
    innerHeightOffset: 0
    key:
      codes:
        space: 32
        left: 37
        right: 39
        up: 38
        down: 40
      map:
        space: 'brake'
        left: 'left'
        right: 'right'
        up: 'forward'
        down: 'reverse'
        d: 'decoy'
        f: 'fire'
        i: 'info'
        o: 'stats'
        s: 'suicide'
    mouse:
      event:
        types: ['click', 'enter', 'leave', 'press', 'release']
    pager:
      color: '#0f0'
      fade: 30
      font: '12px Courier New'
      maxlines: 20
      ttl: 60 * 8
      xoffset: 10
      yoffset: 12
    player:
      loglen: 1 << 8
    types:
      proximal: [
        'Projectile',
        'Explosion',
        'Star'
      ]
      update: [
        'InterpolatedShip',
        'Explosion',
        'ExplosionView',
        'Projectile',
        'ModeledView',
        'Arrow',
        'ShipView'
      ]
    view:
      alpha: 1
      events: {}
  server:
    projectileCollidableTypes: [ 'Ship', 'Star' ]
    game:
      width: (1 << 17) + 1
      height: (1 << 17) + 1
      stars: 4000
      rates:
        friction: 0.99
        partition: 100
    ship:
      width: 20
      height: 20
    starKid:
      rates:
        GasStation: 0.2 # probability of a star having a gas station
        Market: 0.4
        # Mine:
        #   silver: 0.2
        #   gold: 0.1
        #   platinum: 0.05
        #   ununpentium: 0.01

    updatesPerStep: 5
  common:
    url:
      address: 'localhost' #'192.168.0.100'
      port: 3000
    button:
      width: 50
      height: 50
      offset: [0, -8]
      colors:
        background: '#666'
        hover: '#888'
        click: '#444'
        text: '#fff'
      font:
        string: '12px Courier New'
        offset: [10, 4]
    chars:
      peso: '\u03df'
    explosions:
      default:
        colors:
          stroke: '#ff0'
          fill: '#fff'
        damageRate: 0.6
        strength: 100
    fuel:
      distance: 50 # max refueling distance
      price:
        min: 0.8
        max: 1.9
    model:
      width: 10
      height: 10
      veloctiy: [0,0]
    modifiers:
      bits:
        alt: 1
        ctrl: 2
        meta: 4
        shift: 8
    msPerFrame: 16
    projectile:
      damage: 2
      life: 60 * 3
      speed: 10
    ringbuffer:
      max: 50
    ship:
      rates:
        acceleration: 2
        brake: 0.96
        fire: 4
        turn: 0.06
