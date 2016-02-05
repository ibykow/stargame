(module ? {}).exports = class Olib
  @ids = {}
  constructor: (@data = {}) ->
  at: (type, id) ->
    ret = @data[type] or {}
    ret = ret[id] if id
    return ret

  each: ->
    length = arguments.length
    return unless length > 0

    type = null

    if length is 1 then callback = arguments[0]
    else
      callback = arguments[1]
      type = arguments[0]

    return unless typeof callback is 'function'

    if type then callback o, id, type for id, o of @at type
    else (callback o, id, type for id, o of dict) for type, dict of @data

  filter: (test) ->
    return unless typeof test is 'function'
    results = []
    @each (o, id, type) -> results.push o if callback o, id, type
    return results

  get: (type, id) -> @data[type]?[id]

  map: (callback) ->
    return unless typeof callback is 'function'
    ret = {}
    for type, dict of @data when Object.keys(dict).length
      ret[dict] = {}
      (ret[dict][id] = callback o, id, type) for id, o of dict

    return ret

  put: ->
    if arguments.length > 2
      obj = arguments[2] or {}
      obj.id = arguments[1]
      obj.type = arguments[0]
    else
      obj = arguments[0]

    return unless obj?.type

    @data[obj.type] ?= {}
    obj.id ?= arguments[1] or Olib.ids[obj.type] or 1
    Olib.ids[obj.type] = obj.id + 1 unless Olib.ids[obj.type] > obj.id

    @data[obj.type][obj.id] = obj

  remove: ->
    switch arguments.length
      when 0 then return
      when 1 then {type, id} = arguments[0]
      else (type = arguments[0]) and (id = arguments[1])

    return unless type and id
    delete @data[type]?[id]
