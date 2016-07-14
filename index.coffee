((root, factory) ->
  if typeof define == 'function' and define.amd # AMD
    define [ 'jquery' ], factory
  else if typeof module == 'object' and module.exports # Node
    module.exports = factory require('lodash'), require('q').defer, require('najax')
  else if root.angular # AngularJS
    root.angular.module('hybind', []).factory 'hybind', ['$q', '$http',
      (q, http) ->
       req = (opts) ->
         d = q.defer()
         http(opts).then (res) ->
           d.resolve res.data, res
         d.promise
       factory root.angular, q.defer, req ]
  else
    root.hybind = factory(root.jQuery or root.$)
) this, (fw, deferred, http) ->
  extend = fw.extend
  promise = if deferred then (d) -> d.promise else (d) -> d.promise()
  deferred ?= fw.Deferred
  http ?= fw.ajax
  selfLink = (obj) -> obj?.$bind?.self
  clean = (url) -> url.replace /{.*}/g, ''
  str = (obj) -> JSON.stringify obj, (k,v) ->
    v if k is "" or not v?.$bind
  makeUrl = (baseUrl, pathOrUrl) ->
    baseUrl += '/' if baseUrl[-1..] != '/'
    if pathOrUrl.indexOf(':') == -1 then baseUrl + pathOrUrl else pathOrUrl
  hybind = (url, defaults) ->
    defaults ?= {}
    defaults.headers ?= {}
    extend defaults.headers, Accept: 'application/json'
    idFn = -> throw 'No id function defined'
    bind = (item)->
      if item?._links
        for name, link of item._links
          if name != 'self'
            p = item[name] or item[name] = {}
            item.$bind p, link.href
            bind item[name]
          else
            item.$bind.self = clean link.href
        item._links = undefined
    collMapper = (obj, coll, opts) ->
      coll.length = 0
      if obj._embedded
        for k,v of obj._embedded
          for item in v
            link = item?._links?.self?.href
            coll.push item
            if link
              enrich item, link
              item.$bind.ref = coll?.$bind?.self+'/'+link.split('/')[-1..]
            bind item
          break
    req = (r, params) ->
      d = deferred()
      opts = {}
      extend opts, defaults
      extend opts, r
      opts.headers = {}
      extend(opts.headers, defaults.headers) if defaults.headers
      extend(opts.headers, r.headers) if r.headers
      if typeof opts.data == 'string'
        extend opts.headers, { 'Content-Type': 'text/uri-list' }
      if typeof opts.data == 'object'
        extend opts.headers, { 'Content-Type': 'application/json' }
        opts.data = str opts.data
      if params
        sep = if opts.url.indexOf('?') == -1 then '?' else '&'
        opts.url = opts.url + sep + ((k+"="+v) for k,v of params).join("&")
      hybind.http(opts).then (data, s, r) ->
        try
          if typeof data == 'string' and data != ''
            data = JSON.parse(data)
        catch e
          d.reject e
        d.resolve data
      , d.reject
      promise d
    enrich = (obj, url) ->
      obj.$bind = ->
        args = Array.prototype.slice.call arguments
        arg = args[0]
        if typeof arg is 'object'
          target = arg
          args.shift()
        else
          prop = arg
          target = obj[prop] or obj[prop] = {}
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
        pathOrUrl = clean pathOrUrl
        if not target.$bind
          enrich target, makeUrl selfLink(obj), pathOrUrl
        else
          target.$bind.ref = clean makeUrl selfLink(obj), pathOrUrl
          target
      if url
        obj.$bind.ref = clean url
        obj.$bind.self ?= obj.$bind.ref
      obj.$load = (params, opts) ->
        d = deferred()
        req {method: 'GET', url: obj.$bind.ref}, params
        .then (data) ->
          if (obj instanceof Array)
            collMapper data, obj, opts
          else
            for prop of obj
              if typeof obj[prop] != 'function'
                obj[prop] = undefined
            extend obj, data
            bind obj
          d.resolve obj
        , d.reject
        promise d
      if (obj instanceof Array)
        obj.$add = (items) ->
          items = [ items ] if not (items instanceof Array)
          data = (selfLink item for item in items)
          req method: 'POST', url: selfLink(obj), data: data.join '\n'
      else
        obj.$set = (item) ->
          item ?= obj
          req method: 'PUT', url: obj.$bind.ref, data: selfLink item
      obj.$save = -> req method: 'PUT', url: selfLink(obj), data: obj
      obj.$create = (item) ->
        d = deferred()
        req method: 'POST', url: selfLink(obj), data: (item or {})
        .then (data) ->
          extend(item, data) if item
          item ?= data
          enrich item, data._links.self.href
          d.resolve item
        , d.reject
        promise d
      obj.$delete = ->
        if obj.$bind.self
          req method: 'DELETE', url: obj.$bind.self
        else
          obj.$load().then -> req method: 'DELETE', url: obj.$bind.self
      removeLink = selfLink obj
      obj.$remove = -> req method: 'DELETE', url: obj.$bind.ref
      obj.$share = (cache, prop, cb) ->
        if not cb and typeof prop == 'function'
          cb = prop
          prop = undefined
        item = if prop then obj[prop] else obj
        link = selfLink item
        cache ?= defaults?.cache
        cached = cache[link]
        if prop and cached then obj[prop] = cached
        cache[link] = item if not cached
        if cb and not cached then cb item
        item
      obj
    root = $id: (fn) -> idFn = fn
    enrich root, url
  hybind.http = http
  hybind
