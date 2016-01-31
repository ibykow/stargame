Config = require '../coffee/config'
Util = require '../coffee/Util'
Benchmark = require '../coffee/benchmark'
WrapMe = require './fixtures/wrapme'

describe 'Benchmark', ->
  [bench, key, originals, target, targetLyric] = []
  f = (x = 1) -> (n for n in [x..x + 10000]).reduce (a, b) -> a + b
  checksum = f()

  testWrapper = ->
    wrappers = target._benchmarkFunctions

    expect(wrappers.callme).toBe originals.callme
    expect(wrappers.maybe).toBe originals.maybe
    expect(wrappers.definitely).not.toBeDefined()

    expect(target.callme).not.toBe originals.callme
    expect(target.maybe).not.toBe originals.maybe
    expect(target.definitely).not.toBeDefined()

    expect(target.callme(target)).toBe 'passed'
    expect(target.maybe(target, targetLyric)).toBe 'passed'

    expect(bench.getResult 'maybe').toBeDefined()

  beforeEach ->
    bench = new Benchmark
    key = 'master'
    target = new WrapMe()
    targetLyric = WrapMe.reason
    originals =
      callme: target.callme
      maybe: target.maybe

  describe '.new', ->
    it 'should create a new benchmark tool', ->
      expect(bench).toBeDefined()
      expect(bench.stats[key]).not.toBeDefined()

      if process?.hrtime then source = 'process.hrtime'
      else if window?.performance?.now then source = 'window.performance.now'
      else source = 'Date.now()'

      expect(bench.source).toBe source

    it 'should wrap all named functions of a provided target', ->
      bench = new Benchmark target
      testWrapper()

  describe '.start', ->
    it 'should start running the timer', ->
      t = Date.now()
      bench.start()
      stat = bench.stats[key]
      expect(stat).toBeDefined()
      expect(stat.result.start.time - t).toBeLessThan 2

    it "shouldn't interrupt once started", ->

      bench.start()
      stat = bench.stats[key]
      expect(stat).toBeDefined()
      f()
      source = stat.result.start.source
      interruptionReference = bench.ttime()
      error = bench.start()

      expect(error).toBeDefined()
      expect(error.constructor).toBe Error
      expect(error.message).toBe "Benchmark: '" + key + "' is already running."
      expect(stat.running).toBe true
      expect(stat.result.start.source).toEqual source

      f()
      bench.stop()

      diff = bench.tdiff interruptionReference, stat.result.stop.source
      expect(stat.result.delta).toBeGreaterThan diff

  describe '.stop', ->
    it 'should stop the timer and return the delta', ->
      bench.start()
      stat = bench.stats[key]
      expect(stat).toBeDefined()

      f()
      delta = bench.stop key

      expect(stat.running).toBe false
      expect(stat.result).toBeDefined()
      expect(stat.result.delta).toBe delta
      expect(delta).toBeGreaterThan 0

  describe '.bench', ->
    it 'should benchmark a particular function', ->
      reference = 0
      stat = bench.stats[key]
      expect(stat).not.toBeDefined()

      bench.bench ->
        stat = bench.stats[key]
        expect(stat).toBeDefined()
        expect(stat.running).toBe true
        reference = f()

      expect(stat.running).toBe false
      expect(reference).toEqual checksum

  describe '._log', ->
    it 'should print out some stuff to the console', ->
      expect(bench._log_type).toBeDefined()
      expect(bench._log).toBeDefined()
      expect(bench._info).toBeDefined()
      expect(bench._warn).toBeDefined()
      expect(bench._fail).toBeDefined()

      console.log 'The next four console messages should be Benchmark ' +
        'messages including two INFOs, and a WARNNING. These are normal ' +
        'and are being expected. Please ignore them.'

      bench._log 'Hello, World!'
      bench._info()
      bench._info 'Pong'
      bench._warn "This will be your first and last."
      expect(bench._fail "Ya dun goof'd!").toBeDefined()

  describe '.wrap', ->
    it "should wrap a target's functions with calls to @mark", ->
      expect(target._benchmarkFunctions).not.toBeDefined()

      console.log 'The next console message should read ' +
        '"Benchmark WARNING"... This is normal and is being expected. ' +
        'Please ignore it.'

      bench.wrap target, ['callme', 'maybe', 'definitely']
      testWrapper()

    it 'should benchmark a benchmark', ->
      bench.wrap target
      testBench = new Benchmark bench
      target.callme() for [1..1000]
      console.log 'testBench:', testBench, target

  describe '.unwrap', ->
    it "should unwrap all the target's functions", ->
      bench.wrap target
      testWrapper()
      bench.unwrap target

      expect(target._benchmarkFunctions).not.toBeDefined()
      expect(target.callme).toBe originals.callme
      expect(target.maybe).toBe originals.maybe

      expect(target.callme(target)).toBe 'passed'
      expect(target.maybe(target, targetLyric)).toBe 'passed'
