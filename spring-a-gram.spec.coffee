describe 'spring-a-gram', ->
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

  it 'should create and remove item in gallery', (done) ->
    api = @api
    gallery = api.$bind('galleries').$bind('1')
    item = image: '1'
    items = gallery.$bind "items", []
    count = -1
    api.$load()
    .then ->
      api.items.$create item
    .then ->
      item.$load()
    .then ->
      expect(item.image).toBe '1'
      items.$load()
    .then ->
      count = items.length
      item.gallery.$set gallery
    .then ->
      items.$load()
    .then ->
      expect(items.length).toBe count+1
    .then ->
      item.$delete()
    .then ->
      items.$load()
    .then ->
      expect(items.length).toBe count
      done()
