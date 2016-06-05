describe 'spring-a-gram', ->
  Q = require 'q'
  beforeEach ->
    @hybind = require './index.coffee'
    @api = @hybind 'http://localhost:8080/api/',
      headers: Authorization: 'Basic Z3JlZzp0dXJucXVpc3Q='

  it 'should load api', (done) ->
    api = @api
    @api.$load().then ->
      expect(api.items).toBeDefined()
      expect(api.galleries).toBeDefined()
      done()

  it 'should move items across galleries', (done) ->
    api = @api
    api.$bind 'items', []
    api.$bind 'galleries', []
    galleries = api.galleries
    items = []
    check = (items) ->
      two = items.filter (item) -> item.image == '2'
      three = items.filter (item) -> item.image == '3'
      return two.length > 0 and three.length > 0
    galleries.$load()
    .then ->
      galleries[0].$bind 'items', []
      api.items.$create image: '2'
    .then (item) ->
      items.push item
      galleries[0].items.$add item
     .then ->
       api.items.$create image: '3'
     .then (item) ->
       items.push item
       galleries[0].items.$add item
     .then ->
       galleries[0].items.$load()
     .then ->
       expect(check galleries[0].items).toBe true
       galleries[1].$bind 'items', []
       galleries[1].items.$add items
     .then ->
       galleries[0].items.$load()
     .then ->
       expect(check galleries[0].items).toBe false
       galleries[1].items.$load()
     .then ->
       expect(check galleries[1].items).toBe true
       item.$delete() for item in galleries[1].items
       done()
