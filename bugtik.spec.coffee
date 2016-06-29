describe 'bugtik', ->
  Q = require 'q'
  beforeEach ->
    @hybind = require './index.coffee'
    @api = @hybind 'http://localhost:8080/api/'

  it 'should load api', (done) ->
    api = @api
    @api.$load()
    .then ->
      expect(api.tickets).toBeDefined()
      expect(api.projects).toBeDefined()
      expect(api.severities).toBeDefined()
      done()
    .done()

  xit 'should create and assign severity', (done) ->
    api = @api
    api.$bind 'severities', []
    api.$bind 'colors', []
    important = {}
    yellow = code: '#EEEE11'
    api.severities.$bind(important, 'important').$save()
    .then ->
      api.severities.$load()
    .then ->
      found = (s for s in api.severities.filter (s) -> s.name == 'important')
      expect(found.length).toBeGreaterThan 0
      api.colors.$load()
    .then ->
      api.colors.$bind(yellow, 'yellow').$save()
    .then ->
      important.$bind('color').$set yellow
    .then ->
      api.$bind('tickets', []).$load()
    .then ->
      api.tickets[0].$bind('severity').$load()
    .then ->
      expect(api.tickets[0].severity.name).toBe 'normal'
      api.tickets[0].severity.$set important
    .then ->
      api.tickets[0].severity.$load()
    .then ->
      api.tickets[0].severity.color.$load()
    .then ->
      expect(api.tickets[0].severity.color.name).toBe 'yellow'
      api.tickets[0].severity.$set api.severities[1]
    .then ->
      api.tickets[0].severity.$load()
    .then ->
      api.tickets[0].severity.color.$load()
    .then ->
      expect(api.tickets[0].severity.color.name).toBe 'blue'
    .then ->
      important.$delete()
    .then done
    .done()

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
    .done()

  xit 'should find by owner', (done) ->
    @api.$load().then (api) ->
      api.tickets.$bind('search').$load()
    .then (search) ->
      search.findByOwner.$load(owner: 'me')
    .then (results) ->
      console.log results
      expect(result.length).toBe 1
      done()
    .done()
