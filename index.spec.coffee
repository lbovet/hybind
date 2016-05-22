hybind = require './index.coffee'
hybind.request = jasmine.createSpy 'request'
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
  id = (x) -> x.name
  it 'should create a self link with given link', ->
    api.$bind john, 'john'
    expect(john._links.self).toBe 'http://localhost/john'
  it 'should create a self link with default id function', ->
    api.$id id
    api.$bind john
    expect(john._links.self).toBe 'http://localhost/john'
  it 'should create a self link with custom id function', ->
    api.$bind john, id
    expect(john._links.self).toBe 'http://localhost/john'
