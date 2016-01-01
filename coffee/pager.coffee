# Pager - Write temporary messages to the bottom of the screen
if require?
  Config = require './config'
  Util = require './util'
  RingBuffer = require './ringbuffer'

cfg = Config.client.pager

[min] = [Math.min]

(module ? {}).exports = class Pager
  constructor: (@game, maxlines = cfg.maxlines) ->
    return unless @game
    @buffer = new RingBuffer maxlines

  page: (message) ->
    @buffer.insert
      message: message
      ttl: cfg.ttl

  draw: ->
    @buffer.purge (m) -> m.ttl < 1
    @buffer.map (m, i, buf) =>
      yoffset = @game.canvas.height - cfg.yoffset * (buf.length - i)
      @game.c.fillStyle = cfg.color
      @game.c.font = cfg.font
      @game.c.globalAlpha = min m.ttl / cfg.fade, 1
      @game.c.fillText m.message, cfg.xoffset, yoffset
      m.ttl--
