# Pager - Write temporary messages to the bottom of the screen
if require?
  Config = require './config'
  Util = require './util'
  RingBuffer = require './ringbuffer'

conf = Config.client.pager

{min} = Math

(module ? {}).exports = class Pager
  constructor: (@game, @fade = conf.fade, maxlines = conf.maxlines) ->
    return unless @game?
    @ring = new RingBuffer maxlines

  page: (message) ->
    @ring.insert
      message: message
      ttl: conf.ttl

  draw: ->
    @ring.purge (m) -> m.ttl < 1
    entries = @ring.toArray()
    for entry, i in entries
      yoffset = @game.canvas.height - conf.yoffset * (entries.length - i)
      @game.c.fillStyle = conf.color
      @game.c.font = conf.font
      @game.c.globalAlpha = min entry.ttl / @fade, 1
      @game.c.fillText entry.message, conf.xoffset, yoffset
      entry.ttl--
