people = require './fixtures/people'
Olib = require '../coffee/olib'

describe 'Olib', ->
  [lib] = []

  afterEach -> Olib.ids = {}
  beforeEach ->
    lib = new Olib()
    lib.put person for person in people

  describe 'new', ->
    it 'should create a new object library', ->
      expect(lib).toBeDefined()
      expect(typeof lib.data).toBe 'object'

  describe 'at', ->
    it 'should return an empty object for non-existent types', ->
      expect(lib.at 'Fred').toEqual {}
      expect(lib.at 324234).toEqual {}
      expect(lib.at null).toEqual {}

    it 'should return the values for a given type', ->
      dict = lib.at 'Person'
      expect(dict).toBeDefined()
      expect(typeof dict).toBe 'object'

      for person in people
        expect(person.id).toBeGreaterThan 0
        expect(dict[person.id]).toBe person

  describe 'get', ->
    it 'should return undefined when given an invalid type and/or id', ->
      expect(lib.get()).not.toBeDefined()
      expect(lib.get null).not.toBeDefined()
      expect(lib.get null, null).not.toBeDefined()
      expect(lib.get 'Person').not.toBeDefined()
      expect(lib.get 'Person', null).not.toBeDefined()
      expect(lib.get 'Person', false).not.toBeDefined()
      expect(lib.get 'Person', 0).not.toBeDefined()
      expect(lib.get 'FFF').not.toBeDefined()

  describe 'put', ->
    it 'should insert entries', ->
      expect(Olib.ids['Person']).toBe people.length + 1

    it 'should ignore invalid entries', ->
      lib = new Olib()
      lib.put()
      lib.put 'Fred'
      lib.put 'Fred', 32
      lib.put
        name: 'Fred'
        id: 23

      expect(lib.data).toEqual {}

    it 'should overwrite existing data', ->
      firstPerson = people[0]
      expect(lib.get 'Person', firstPerson.id).toBe firstPerson

      firstName = firstPerson.name
      secondName = firstName + '-Newton'
      id = parseInt firstPerson.id

      lib.put 'Person', id, name: secondName
      secondPerson = lib.get 'Person', id

      expect(id).toBe firstPerson.id
      expect(secondPerson).not.toBe firstPerson
      expect(secondPerson.name).toBe secondName
      expect(firstPerson.name).toBe firstName

      thirdName = secondName + '-Wilde'
      thirdPerson =
        name: thirdName
        id: id
        type: 'Person'

      lib.put thirdPerson
      person = lib.get 'Person', id
      expect(person).toBe thirdPerson
      expect(person).not.toBe firstPerson
      expect(person).not.toBe secondPerson
      expect(person.id).toBe id
      expect(person.id).toBe firstPerson.id
      expect(person.id).toBe secondPerson.id
      expect(person.id).toBe thirdPerson.id
      expect(person.name).toBe thirdName
      expect(thirdName).not.toBe firstName
      expect(thirdName).not.toBe secondName
      expect(thirdName).not.toBe firstPerson.name
      expect(thirdName).not.toBe secondPerson.name

  describe 'remove', ->
    it 'should remove entries', ->
      expect(Object.keys(lib.at 'Person').length).toBe people.length
      person = people[0]
      expect(lib.get person.type, person.id).toBe person
      lib.remove person
      expect(lib.get person.type, person.id).not.toBeDefined()
      expect(people[0]).toBe person
