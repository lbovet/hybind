((root, factory) ->
  if typeof define == 'function' and define.amd # AMD
    define [ 'jquery' ], factory
  else if typeof module == 'object' and module.exports # Node
    module.exports = factory require('lodash'), require('q').defer, require('najax')
  else if root.angular # AngularJS
    root.angular.module('hybind', []).factory 'api', ['$q', '$http',
     (q, http) -> factory root.angular, $q.defer, $http ]
  else
    root.hybind = factory(root.jQuery or root.$)
) this, (fw, deferred, http) ->
  extend = fw.extend
  promise = if deferred then (d) -> d.promise else (d) -> d.promise()
  deferred ?= fw.Deferred
  http ?= fw.ajax
  selfLink = (obj) -> obj?._links?.self?.href
  str = (obj) -> JSON.stringify obj, (k,v) -> v if k != '_links'
  makeUrl = (baseUrl, pathOrUrl) ->
    baseUrl += '/' if baseUrl[-1..] != '/'
    if pathOrUrl.indexOf(':') == -1 then baseUrl + pathOrUrl else pathOrUrl
  hybind = (url) ->
    idFn = -> throw 'No id function defined'
    collMapper = (obj, coll) ->
      coll.length = 0
      if obj._embedded
        for k,v of obj._embedded
          for item in v
            coll.push item
            link = selfLink item
            enrich item, link if link
          break
    req = (opts, params) ->
      if typeof opts.data == 'string'
        opts.headers = { 'Content-Type': 'text/uri-list' }
      if typeof opts.data == 'object'
        opts.headers = { 'Content-Type': 'application/json' }
        opts.data = str opts.data
      if params
        sep = if opts.url.indexOf('?') == -1 then '?' else '&'
        opts.url = opts.url + sep + ((k+"="+v) for k,v of params).join("&")
      hybind.http opts
    enrich = (obj, url) ->
      if url then obj._links = self: href: url
      obj.$bind = ->
        args = Array.prototype.slice.call arguments
        arg = args[0]
        if typeof arg is 'object'
          target = arg
          args.shift()
        else
          prop = arg
          target = obj[prop] = {}
        link = args[0]
        link = link target if typeof link is 'function'
        link = idFn target if link is undefined
        arg = args[1]
        if typeof arg is 'object'
          target = arg
          obj[prop] = target if prop
          args.shift()
        pathOrUrl = args[1]
        pathOrUrl ?= link
        enrich target, makeUrl selfLink(obj), pathOrUrl
      obj.$load = (params) ->
        d = deferred()
        req {method: 'GET', url: selfLink obj}, params
        .then (data) ->
          if (obj instanceof Array)
            collMapper data, obj
          else
            for prop of obj
              if prop.indexOf('_') != 0 and typeof obj[prop] != 'function'
                delete obj[prop]
            extend obj, data
            if data?._links
              for name, link of data._links
                if name != 'self'
                  p = obj[name] = {}
                  obj.$bind p, link.href
          d.resolve obj
        promise d
      if (obj instanceof Array)
        obj.$add = (items) ->
          items = [ items ] if not (items instanceof Array)
          data = (selfLink item for item in items)
          req method: 'POST', url: selfLink(obj), data: data.join '\n'
      else
        obj.$set = (item) -> req method: 'PUT', url: selfLink(obj), data: selfLink item
      obj.$save = -> req method: 'PUT', url: selfLink(obj), data: obj
      obj.$delete = -> req method: 'DELETE', url: selfLink(obj)
      removeLink = selfLink obj
      obj.$remove = -> req method: 'DELETE', url: removeLink
      obj
    root = $id: (fn) -> idFn = fn
    enrich root, url
  hybind.http = http
  hybind
