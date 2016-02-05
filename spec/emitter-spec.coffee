Config = require '../coffee/config'
Util = require '../coffee/Util'
Olib = require '../coffee/olib'
Emitter = require '../coffee/emitter'

isnum = Util.isNumeric

describe 'Emitter', ->
  [child, em, game] = []

  afterEach -> Olib.ids = {}

  beforeEach ->
    game =
      emit: ->
      lib: new Olib()
      page: console.log.bind console
      tick:
        count: 0

  testCallback = -> game.tick.count++

  expectChild = ->
    expect(child).toBeDefined()
    expect(child.parent).toBe em
    expect(em.children.get child.type, child.id).toBe child

  # TODO: Check if body of function is empty
  expectBlankFunc = (n) -> it 'is a blank function', ->
    expect(typeof em[n]).toBe 'function'

  expectHandler = (h, name, params) ->
    {callback, now, repeats, timeout} = params

    timeout ?= 0
    repeats ?= true
    now ?= false

    expect(h).toBeDefined()
    expect(h.callback).toBeDefined()
    expect(h.callback).toBe callback
    expect(h.repeats).toBe repeats
    expect(h.timedOut).toBe false
    if timeout > 0 then expect(h.timer).toBeDefined()
    else expect(h.timer).toBeNull()

    if now then type = 'immediates' else type = 'listeners'
    len = em[type][name].length

    expect(len).toBeGreaterThan 0
    expect(em[type][name][len - 1]).toBe h

  expectNew = ->
    expect(em).toBeDefined()
    expect(em.id).toBeGreaterThan 0
    expect(em.game).toBe game
    expect(em.type).toBe 'Emitter'
    expect(game.lib.get 'Emitter', em.id).toBe em
    expect(em.type).toBe 'Emitter'

  expectRemoved = (emitter) ->
    expect(game.lib.get emitter.type, emitter.id).not.toBeDefined()
    expect(emitter.parent).toBe null
    expect(emitter.children).toEqual {}
    expect(emitter.listeners).toEqual {}
    expect(emitter.immediates).toEqual {}

  describe 'class side', ->
    it 'should have a dictionary of events', ->
      expect(typeof Emitter.events).toBe 'object'

    it 'should have a valid ids table', -> expect(Emitter.ids).toEqual {}

    describe '@fromState', ->
      it 'creates a new emitter when no state is provided', ->
        em = Emitter.fromState game
        expectNew()

    describe '@processHandlers', ->
      it 'call back handlers at a given name', ->

    describe '@run', ->
      it 'runs the regular event loop', ->

  describe 'instance side', ->
    name = 'something'

    beforeEach -> em = new Emitter game

    describe '.new', ->
      it 'creates a new emitter object', expectNew
      it 'gets adopted by a parent', ->
        child = new Emitter game, parent: em
        expectChild()

    describe '.adopt', ->
      it 'adopts a child', ->
        child = new Emitter game
        em.adopt child
        expectChild()

    describe '.delete', ->
      it 'removes references to the emitter', ->
        child = new Emitter game, parent: em
        em.on 'wake', ->
        em.now 'sleep', ->
        child.on 'sleep', ->
        child.now 'wake', ->

        expect(em.listeners.wake.length).toBeGreaterThan 0
        expect(child.listeners.sleep.length).toBeGreaterThan 0

        expectNew()
        expectChild()
        em.delete()
        expectRemoved child
        expectRemoved em

    describe '.emit', ->
      it 'emits an event', ->

    describe '.getState', ->
      it 'returns an object containing id and type', ->
        state = em.getState()
        expect(state.id).toBe em.id
        expect(state.type).toBe em.type

      it 'should not exist if the emitter is deleted', ->
        expect(em.isDeleted()).toBe false
        em.delete()
        expect(em.isDeleted()).toBe true
        expect(em.getState).toBe null

    describe '.initHandlers', -> expectBlankFunc 'initHandlers'

    describe '.isDeleted', ->
      it 'reports whether the object has been deleted', ->
        child = new Emitter game, parent: em
        em.on 'wake', ->
        child.on 'sleep', ->

        expect(em.listeners.wake.length).toBeGreaterThan 0
        expect(child.listeners.sleep.length).toBeGreaterThan 0

        expect(em.isDeleted()).toBe false
        expect(child.isDeleted()).toBe false

        em.delete()

        expect(em.isDeleted()).toBe true
        expect(child.isDeleted()).toBe true

    describe '.now', ->
      it 'registers an immediate-execution callback for an event', ->
        handler = em.now name, testCallback
        expectHandler handler, name,
          callback: testCallback
          now: true

    describe '.on', ->
      it 'registers a callback for an event', ->
        handler = em.on name, testCallback
        expectHandler handler, name, callback: testCallback

      it 'registers a handler for an event', ->
        handler = em.on name, callback: testCallback
        expectHandler handler, name, callback: testCallback

        params =
          callback: testCallback
          timeout: 12
          repeats: false
          now: true

        handler = em.on name, params
        expectHandler handler, name, params

    describe '.once', ->
      it 'registers a one-time callback for an event', ->
        handler = em.once name, testCallback
        expectHandler handler, name,
          callback: testCallback
          repeats: false

    describe '.setState', ->
      it 'sets the id and type from the argument', ->
        expect(em.type).not.toBe 'LambChop'
        state =
          id: em.id + 10
          type: 'LambChop'

        em.setState state
        expect(em.id).toBe state.id
        expect(em.type).toBe state.type
        expect(em.type).not.toBe 'Emitter'
