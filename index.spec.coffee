describe 'hybind', ->
  Q = require 'q'
  api = undefined
  john = null
  request = null
  hybind = require './index.coffee'

  beforeEach ->
    api = hybind 'http://localhost'
    john = name: 'john'
    request = jasmine.createSpy('request').andReturn Q()
    hybind.request = request

  describe 'root api', ->
    it 'should have self link', ->
      expect(api._links.self.href).toBe 'http://localhost'
    it 'should have $bind function', ->
      expect(typeof api.$bind).toBe 'function'

  describe '$bind', ->
    describe 'without object', ->
      it 'should create a property object', ->
        api.$bind 'hello'
        expect(typeof api.hello).toBe 'object'
      it 'should have a matching self link', ->
        obj = api.$bind 'hello'
        expect(obj._links.self.href).toBe 'http://localhost/hello'
      it 'should have an overridable url', ->
        obj = api.$bind 'hello', 'http://remotehost'
        expect(obj._links.self.href).toBe 'http://remotehost'

    describe 'with object', ->
      it 'should create a self link with given link', ->
        api.$bind john, 'j'
        expect(john._links.self.href).toBe 'http://localhost/j'
      it 'should create a self link with default id function', ->
        api.$id () -> 'jo'
        api.$bind john
        expect(john._links.self.href).toBe 'http://localhost/jo'
      it 'should create a self link with custom id function', ->
        api.$bind john, (x) -> x.name
        expect(john._links.self.href).toBe 'http://localhost/john'
      it 'should have an overridable url', ->
        api.$bind john, null, 'http://remotehost'
        expect(john._links.self.href).toBe 'http://remotehost'
      it 'should fail if id function is missing', ->
        expect(-> api.$bind john).toThrow 'No id function defined'

    describe 'collections', ->
      it 'should be supported as parameter', ->
        addresses = []
        api.$bind addresses, 'addresses'
        expect(addresses._links.self.href).toBe 'http://localhost/addresses'
      it 'should be supported as property', ->
        addresses = []
        api.$bind 'addresses', addresses
        expect(api.addresses).toBe addresses

  describe 'operations', ->
    beforeEach ->
      api.$bind john, 'john'
    describe '$load', ->
      it 'should issue a GET request', ->
        john.$load()
        expect(request).toHaveBeenCalledWith jasmine.objectContaining
          method: 'GET', uri: 'http://localhost/john'
      it 'should replace the object content but not remove the $ functions and links', (done) ->
        request.andReturn Q age: 22
        john.$load().then (newJohn) ->
          expect(john).toBe newJohn
          expect(john.age).toBe 22
          expect(john.name).toBeUndefined()
          expect(john.$load).toBeDefined()
          expect(john._links).toBeDefined()
          done()
      it 'should replace the links if they are present', (done) ->
        request.andReturn Q _links: self: href: 'http://remotehost/john'
        john.$load().then ->
          expect(john._links.self.href).toBe 'http://remotehost/john'
          done()
      it 'should create properties from links', (done) ->
        request.andReturn Q _links:
          self: href: john._links.self.href
          address: href: 'http://localhost/john/address'
        john.$load().then ->
          expect(john.address).toBeDefined()
          expect(john.address._links.self.href).toBe 'http://localhost/john/address'
          done()
    describe '$save', ->
      it 'should issue a PUT request', (done) ->
        john.$save().then ->
          expect(request).toHaveBeenCalledWith jasmine.objectContaining
            method: 'PUT', uri: 'http://localhost/john'
            JSON.stringify data: name: 'john'
          done()

    describe '$delete', ->
      it 'should issue a DELETE request', (done) ->
        john.$delete().then ->
          expect(request).toHaveBeenCalledWith jasmine.objectContaining
            method: 'DELETE', uri: 'http://localhost/john'
          done()
