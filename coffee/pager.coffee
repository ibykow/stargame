# Pager - Write temporary messages to the bottom of the screen
if require?
  Config = require './config'
  Util = require './util'
  RingBuffer = require './ringbuffer'

cfg = Config.client.pager

{min} = Math

(module ? {}).exports = class Pager
  constructor: (@game, @fade = cfg.fade, maxlines = cfg.maxlines) ->
    return unless @game
    @buffer = new RingBuffer maxlines

  page: (message) ->
    @buffer.insert
      message: message
      ttl: cfg.ttl

  draw: ->
    @buffer.purge (m) -> m.ttl < 1
    entries = @buffer.toArray()
    for entry, i in entries
      yoffset = @game.canvas.height - cfg.yoffset * (entries.length - i)
      @game.c.fillStyle = cfg.color
      @game.c.font = cfg.font
      @game.c.globalAlpha = min entry.ttl / @fade, 1
      @game.c.fillText entry.message, cfg.xoffset, yoffset
      entry.ttl--
