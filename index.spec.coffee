describe 'hybind', ->
  Q = require 'q'

  beforeEach ->
    @hybind = require './index.coffee'
    @api = @hybind 'http://localhost'
    @john = name: 'john'
    @http = jasmine.createSpy('http').andReturn Q()
    @hybind.http = @http

  describe 'root api', ->
    it 'should have self link', ->
      expect(@api.$bind.self).toBe 'http://localhost'
    it 'should have $bind function', ->
      expect(typeof @api.$bind).toBe 'function'

  describe '$bind', ->
    describe 'without object', ->
      it 'should create a property object', ->
        @api.$bind 'hello'
        expect(typeof @api.hello).toBe 'object'
      it 'should bind numeric values', ->
        obj = @api.$bind 2
        expect(obj.$bind.self).toBe 'http://localhost/2'
      it 'should have a matching self link', ->
        obj = @api.$bind 'hello'
        expect(obj.$bind.self).toBe 'http://localhost/hello'
      it 'should keep existing property object', ->
        obj1 = @api.$bind 'hello'
        @api.hello.$bind.self="http://remotehost/hello"
        obj2 = @api.$bind 'hello'
        expect(obj1).toBe obj2
        expect(obj2.$bind.ref).toBe 'http://localhost/hello'
      it 'should have an overridable url', ->
        obj = @api.$bind 'hello', 'http://remotehost'
        expect(obj.$bind.self).toBe 'http://remotehost'
      it 'should use reference from catalog', ->
        @api.$bind.refs = hello: 'http://remotehost/hello'
        obj = @api.$bind 'hello'
        expect(obj.$bind.ref).toBe 'http://remotehost/hello'

    describe 'with object', ->
      it 'should create a self link with given link', ->
        @api.$bind 'j', @john
        expect(@john.$bind.self).toBe 'http://localhost/j'
      it 'should create a self link with default id function', ->
        @api.$id () -> 'jo'
        @api.$bind @john
        expect(@john.$bind.self).toBe 'http://localhost/jo'
      it 'should create a self link with custom id function', ->
        @api.$bind @john, (x) -> x.name
        expect(@john.$bind.self).toBe 'http://localhost/john'
      it 'should have an overridable url', ->
        @api.$bind 'http://remotehost', @john
        expect(@john.$bind.self).toBe 'http://remotehost'
      it 'should fail if id function is missing', ->
        api = @api
        expect(-> api.$bind @john).toThrow 'No property or id specified'
      it 'should rebind new object with previous reference', ->
        @api.$bind 'john', @john
        @john.$bind.ref = 'http://remotehost/john'
        john2 = name: 'john2'
        @api.$bind 'john2', john2
        @api.$bind 'john', john2
        expect(john2.$bind.self).toBe 'http://localhost/john2'
        expect(john2.$bind.ref).toBe 'http://remotehost/john'
      it 'should use reference from catalog', ->
        @api.$bind.refs = john: 'http://remotehost/john'
        obj = @api.$bind 'john', @john
        expect(@john.$bind.ref).toBe 'http://remotehost/john'

    describe 'collections', ->
      it 'should be supported as parameter', ->
        addresses = []
        @api.$bind addresses, 'addresses'
        expect(addresses.$bind.self).toBe 'http://localhost/addresses'
      it 'should be supported as property', ->
        addresses = []
        @api.$bind 'addresses', addresses
        expect(@api.addresses).toBe addresses

  describe 'operations on objects', ->
    beforeEach ->
      @api.$bind @john, 'john'

    describe '$load', ->
      it 'should issue a GET request', ->
        @john.$load()
        expect(@http).toHaveBeenCalledWith jasmine.objectContaining
          method: 'GET', url: 'http://localhost/john'

      it 'should support parameters', ->
        @john.$load p: true
        expect(@http).toHaveBeenCalledWith jasmine.objectContaining
          method: 'GET', url: 'http://localhost/john?p=true'
        @http.reset()
        @api.$bind("paul?v=1").$load p: true
        expect(@http).toHaveBeenCalledWith jasmine.objectContaining
          method: 'GET', url: 'http://localhost/paul?v=1&p=true'

      it 'should replace the object content but not remove the $ functions and not copy links', (done) ->
        @http.andReturn Q age: 22
        john = @john
        john.$load().then (newJohn) ->
          expect(john).toBe newJohn
          expect(john.age).toBe 22
          expect(john.name).toBeUndefined()
          expect(john.$load).toBeDefined()
          expect(john._links).toBeUndefined()
          done()

      it 'should replace the link if present', (done) ->
        @http.andReturn Q _links: self: href: 'http://remotehost/john'
        john = @john
        john.$load().then ->
          expect(john.$bind.self).toBe 'http://remotehost/john'
          done()

      it 'should not replace the association reference if present', (done) ->
        @http.andReturn Q _links: self: href: 'http://remotehost/john'
        john = @john
        john.$load().then ->
          expect(john.$bind.ref).toBe 'http://localhost/john'
          done()

      it 'should create properties from links', (done) ->
        @http.andReturn Q _links:
          self: href: @john.$bind.self
          address: href: 'http://localhost/john/address'
        john = @john
        john.$load().then ->
          expect(john.address).toBeDefined()
          expect(john.address.$bind.self).toBe 'http://localhost/john/address'
          done()

      it 'should create reference catalog', (done) ->
        @http.andReturn Q _links:
          self: href: @john.$bind.self
          address: href: 'http://localhost/john/address'
        john = @john
        john.$load().then ->
          expect(john.$bind.refs.address).toBe 'http://localhost/john/address'
          done()

    describe '$save', ->
      it 'should issue a PUT request', (done) ->
        http = @http
        john = @john
        @john.$save().then (obj) ->
          expect(obj).toBe john
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'PUT', url: 'http://localhost/john'
            data: JSON.stringify name: 'john'
          done()

      it 'should support parameters', (done) ->
        http = @http
        @john.$save(p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/john?p=true'
          done()

    describe '$delete', ->
      it 'should DELETE the loaded self link', (done) ->
        http = @http
        http.andReturn Q _links: self: href: 'http://remotehost/john'
        john = @john
        john.$load().then ->
          john.$delete().then (obj) ->
            expect(obj).toBe john
            expect(http).toHaveBeenCalledWith jasmine.objectContaining
              method: 'DELETE', url: 'http://remotehost/john'
            done()

      it 'should support parameters', (done) ->
        http = @http
        @john.$delete(p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/john?p=true'
          done()

    describe '$create', ->
      it 'without argument should POST empty object', (done) ->
        http = @http
        http.andReturn Q _links: self: href: 'http://localhost/1'
        @api.$create().then (obj) ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'POST', url: 'http://localhost', data: "{}"
          expect(obj.$bind.self).toBe 'http://localhost/1'
          done()

      it 'with argument should POST given object', (done) ->
        http = @http
        http.andReturn Q name: 'bob', _links: self: href: 'http://localhost/1'
        bob = name: 'bob'
        @api.$create(bob).then (obj) ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'POST', url: 'http://localhost',
            data: JSON.stringify name: 'bob'
          expect(obj.$bind.self).toBe 'http://localhost/1'
          expect(bob.$bind.self).toBe 'http://localhost/1'
          done()

      it 'should support parameters', (done) ->
        http = @http
        http.andReturn Q name: 'bob', _links: self: href: 'http://localhost/1'
        @john.$create(null, p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/john?p=true'
          done()

    describe '$remove', ->
      it 'should issue a DELETE request', (done) ->
        http = @http
        john = @john
        @john.$remove().then (obj) ->
          expect(obj).toBe john
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'DELETE', url: 'http://localhost/john'
          done()

      it 'should DELETE the association ref link of loaded objects', (done) ->
        http = @http
        http.andReturn Q _links: self: href: 'http://remotehost/john'
        john = @john
        john.$load().then ->
          http.reset()
          john.$remove().then (obj) ->
            expect(obj).toBe john
            expect(http).toHaveBeenCalledWith jasmine.objectContaining
              method: 'DELETE', url: 'http://localhost/john'
            done()

      it 'should support parameters', (done) ->
        http = @http
        @john.$remove(p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/john?p=true'
          done()

    describe '$set', ->
      it 'should issue a PUT request', (done) ->
        http = @http
        paul = @api.$bind "paul"
        father = @john.$bind "father"
        father.$set(paul).then (obj) ->
          expect(obj).toBe father
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'PUT'
            url: 'http://localhost/john/father'
            data: 'http://localhost/paul'
          done()

      it 'should support parameters', (done) ->
        http = @http
        @john.$set(null, p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/john?p=true'
          done()

    describe '$share', ->
      it 'should cache objects', ->
        cache = {}
        cb = jasmine.createSpy('cb');
        @john.$share cache, cb
        expect(cb).toHaveBeenCalledWith @john
        cb.reset()
        @api.$bind 'john2', { name: 'john2'}, "http://localhost/john"
        shared = @api.$share 'john2', cache
        expect(shared).toBeDefined()
        expect(@api.john2).toBe @john

      it 'without property should not replace objects', ->
        cache = {}
        @john.$share cache
        @api.$bind 'john2', { name: 'john2'}, "http://localhost/john"
        @api.$share 'john2', cache
        expect(@api.john2).toBe @john

  describe 'operations on collections', ->
    beforeEach ->
      @addresses = []
      @api.$bind 'addresses', @addresses

    describe '$load', ->
      it 'should map collections', (done) ->
        addresses = {}
        @api.$bind 'addresses', addresses
        @http.andReturn Q
          _links: self: href: addresses.$bind.self
          _embedded:
            addresses: [
                city: 'London'
                _links: self: href: "http://localhost/london"
              ,
                city: 'Paris'
            ]
          page: number: 0
        addresses.$load().then ->
          expect(addresses.__proto__).toBe Array.prototype
          expect(addresses.$add).toBeDefined()
          expect(addresses.length).toBe 2
          expect(addresses[0].city).toBe 'London'
          expect(addresses[1].city).toBe 'Paris'
          expect(addresses[0].$load).toBeDefined()
          expect(addresses[0].$bind.self).toBe 'http://localhost/london'
          expect(addresses[0].$bind.ref).toBe 'http://localhost/addresses/london'
          expect(addresses[1].$load).toBeUndefined()
          expect(addresses.$resource).toBeDefined()
          expect(addresses.$resource.page.number).toBe 0
          done()
        .done()

    describe '$add', ->
      it 'single item should issue POST', (done) ->
        addresses = @addresses
        http = @http
        item = city: 'New York', $bind: self: "http://localhost/newyork"
        addresses.$add(item).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'POST', url: 'http://localhost/addresses'
            data: 'http://localhost/newyork'
          done()

      it 'items should issue POST', (done) ->
        addresses = @addresses
        http = @http
        items = [
          { city: 'New York', $bind: self: "http://localhost/newyork" },
          { city: 'New Dehli', $bind: self: "http://localhost/newdehli" } ]
        addresses.$add(items).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'POST', url: 'http://localhost/addresses'
            data: 'http://localhost/newyork\nhttp://localhost/newdehli'
          done()

      it 'should support parameters', (done) ->
        addresses = @addresses
        http = @http
        addresses.$add({}, p: true).then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            url: 'http://localhost/addresses?p=true'
          done()

    describe '$remove', ->
      it 'should delete association', (done) ->
        addresses = @addresses
        http = @http
        http.andReturn Q
          _links: self: href: addresses.$bind.self
          _embedded:
            addresses: [
                city: 'London'
                _links: self: href: "http://localhost/london"
              ,
                city: 'Paris'
            ]
        addresses.$load().then ->
          http.reset()
          http.andReturn Q()
          addresses[0].$remove().then ->
            expect(http).toHaveBeenCalledWith jasmine.objectContaining
              method: 'DELETE', url: 'http://localhost/addresses/london'
            done()

    describe '$save', ->
      it 'replaces the collection content', (done) ->
        addresses = @addresses
        http = @http
        addresses.push addresses.$bind "london"
        addresses.push addresses.$bind "paris"
        addresses.$save().then ->
          expect(http).toHaveBeenCalledWith jasmine.objectContaining
            method: 'PUT', url: 'http://localhost/addresses'
            data: "http://localhost/addresses/london\nhttp://localhost/addresses/paris"
          done()
