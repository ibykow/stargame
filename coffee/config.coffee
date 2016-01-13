# Provide configuration data
(module ? {}).exports = Config =
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
    view:
      alpha: 1
      mouse:
        events:
          enter: -> console.log 'Planning on staying long?'
          leave: -> console.log "Please don't leave me!"
          press: -> console.log "Don't press me Mitch."
          release: -> console.log 'Release me. Set me free.'
          click: -> console.log 'You clicked me!'
  server:
    bulletCollidableTypes: [ 'Ship', 'Star' ]
    game:
      width: (1 << 15) + 1
      height: (1 << 15) + 1
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
    bullet:
      damage: 2
      life: 60 * 3
      speed: 10
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
      default:
        enabled: true
    chars:
      peso: '\u03df'
    fuel:
      distance: 50 # max refueling distance
      price:
        min: 0.8
        max: 1.9
    model:
      width: 10
      height: 10
      veloctiy: [0,0]
    msPerFrame: 16
    ringbuffer:
      max: 50
    ship:
      rates:
        acceleration: 2
        brake: 0.96
        fire: 4
        turn: 0.06
