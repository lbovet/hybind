describe 'bugtik', ->
  Q = require 'q'
  beforeEach ->
    @hybind = require './index.coffee'
    @api = @hybind 'http://localhost:8080/api/'

  it 'should load api', (done) ->
    api = @api
    @api.$load().then ->
      expect(api.tickets).toBeDefined()
      expect(api.projects).toBeDefined()
      done()

  it 'should move tickets across projects', (done) ->
    api = @api
    api.$bind 'tickets', []
    api.$bind 'projects', []
    projects = api.projects
    tickets = []
    check = (tickets) ->
      two = tickets.filter (ticket) -> ticket.summary == '2'
      three = tickets.filter (ticket) -> ticket.summary == '3'
      return two.length > 0 and three.length > 0
    projects.$load()
    .then ->
      projects[0].$bind 'tickets', []
      api.tickets.$create summary: '2'
    .then (ticket) ->
      tickets.push ticket
      projects[0].tickets.$add ticket
     .then ->
       api.tickets.$create summary: '3'
     .then (ticket) ->
       tickets.push ticket
       projects[0].tickets.$add ticket
     .then ->
       projects[0].tickets.$load()
     .then ->
       expect(check projects[0].tickets).toBe true
       projects[1].$bind 'tickets', []
       projects[1].tickets.$add tickets
     .then ->
       projects[0].tickets.$load()
     .then ->
       expect(check projects[0].tickets).toBe false
       projects[1].tickets.$load()
     .then ->
       expect(check projects[1].tickets).toBe true
       ticket.$delete() for ticket in projects[1].tickets
       done()
