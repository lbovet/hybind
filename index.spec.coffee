hybind = require './index.coffee'
api = hybind 'http://localhost'
hybind.request = jasmine.createSpy 'request'

describe 'root api', ->
  it 'should create self link', ->
    expect(api._links.self).toBe 'http://localhost'
  it 'should create declare function', ->
    expect(typeof api.$declare).toBe 'function'

describe '$declare', ->
  obj = api.$declare 'hello'
  it 'should create a property object', ->
    expect(typeof api.hello).toBe 'object'
  it 'should have a matching self link', ->
    expect(obj._links.self).toBe 'http://localhost/hello'
  it 'should have an overridable url', ->
    obj2 = api.$declare 'hello', 'http://remotehost'
    expect(obj2._links.self).toBe 'http://remotehost'
