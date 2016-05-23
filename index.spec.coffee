hybind = require './index.coffee'
hybind.request = jasmine.createSpy 'request'

describe 'hybind', ->
  api = undefined
  john = null

  beforeEach ->
    api = hybind 'http://localhost'
    john =
      name: 'john'

  describe 'root api', ->
    it 'should create self link', ->
      expect(api._links.self).toBe 'http://localhost'
    it 'should create declare function', ->
      expect(typeof api.$bind).toBe 'function'

  describe '$bind without object', ->
    it 'should create a property object', ->
      api.$bind 'hello'
      expect(typeof api.hello).toBe 'object'
    it 'should have a matching self link', ->
      obj = api.$bind 'hello'
      expect(obj._links.self).toBe 'http://localhost/hello'
    it 'should have an overridable url', ->
      obj = api.$bind 'hello', 'http://remotehost'
      expect(obj._links.self).toBe 'http://remotehost'

  describe '$bind with object', ->
    it 'should create a self link with given link', ->
      api.$bind john, 'j'
      expect(john._links.self).toBe 'http://localhost/j'
    it 'should create a self link with default id function', ->
      api.$id () -> 'jo'
      api.$bind john
      expect(john._links.self).toBe 'http://localhost/jo'
    it 'should create a self link with custom id function', ->
      api.$bind john, (x) -> x.name
      expect(john._links.self).toBe 'http://localhost/john'
    it 'should have an overridable url', ->
      api.$bind john, null, 'http://remotehost'
      expect(john._links.self).toBe 'http://remotehost'
    it 'should fail if id function is missing', ->
      expect(-> api.$bind john).toThrow 'No id function defined'
