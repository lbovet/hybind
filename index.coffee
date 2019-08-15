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
         http(opts).then ((res) -> d.resolve res.data, res), d.reject
         d.promise
       factory root.angular, q.defer, req ]
  else if root.jQuery or root.$
    root.hybind = factory(root.jQuery or root.$)
  else
    root.hybind = factory()
) this, (fw, deferred, http) ->
  promise = if deferred or not fw then (d) -> d.promise else (d) -> d.promise()
  if fw
    extend = fw.extend
    deferred ?= fw.Deferred
    http ?= fw.ajax
  else
    extend = (first, second) ->
      for secondProp of second
        secondVal = second[secondProp]
        if secondVal and Object::toString.call(secondVal) == '[object Object]'
          first[secondProp] = first[secondProp] or {}
          extend first[secondProp], secondVal
        else
          first[secondProp] = secondVal
      first
    deferred = () ->
      d = {}
      p = new window.Promise (resolve, reject) ->
        d.resolve = resolve
        d.reject = reject
      d.promise = p
      d
    http = (opts) ->
      opts.headers = new Headers opts.headers
      opts.body = opts.data
      d = deferred()
      window.fetch(opts.url, opts).then (res) -> if res.ok then d.resolve res.text() else d.reject res,
        d.reject
      promise(d)
  selfLink = (obj) -> obj?.$bind?.self
  clean = (url) -> String(url).replace /{.*}/g, '' if url
  limitDepth = (object, maxDepth, currentDepth) ->
    if (!(object instanceof Object))
      return;
    if currentDepth == undefined
      currentDepth = 1;
    keys = Object.keys(object);
    for key in keys
      child = object[key];
      if child instanceof Object
        if currentDepth > maxDepth
          delete object[key];
        else
          limitDepth(child, maxDepth, currentDepth + 1)
  str = (obj, attached) ->
    MAX_DEPTH = 2
    limitDepth(obj, MAX_DEPTH)
    array = undefined
    root = true
    JSON.stringify obj, (k,v) ->
      if not root
        if attached and (attached.length == 0 or k in attached) or array
          if not (v instanceof Array)
            result = v?.$bind?.self
          else if (attached.length == 0 or k in attached)
            array = k
            result = v.slice(0)
        if not (typeof k is 'number') and array is not k
          array = false
      root = false
      result or (v if k is '' or not v?.$bind)
  makeUrl = (baseUrl, pathOrUrl) ->
    if not pathOrUrl then return
    baseUrl += '/' if baseUrl[-1..] != '/'
    if pathOrUrl.indexOf(':') == -1 then baseUrl + encodeURI(pathOrUrl) else pathOrUrl
  hybind = (url, defaults) ->
    defaults ?= {}
    defaults.headers ?= {}
    extend defaults.headers, Accept: 'application/json'
    idFn = -> null
    bind = (item)->
      if item?._links
        for name, link of item._links
          self = null
          if name != 'self'
            if (item.$bind?.self != clean link.href) and item[name] != null
              p = item[name] or item[name] = {}
              item.$bind p, link.href
              item.$bind.refs[name] = link.href
              bind item[name]
          else
            item.$bind.self = clean link.href
      if item instanceof Array
        for i in item
          link = i?._links?.self?.href
          if link
            enrich i, link
            bind i
    postCollMap = (obj) -> obj;
    collMapper = (obj, coll) ->
      coll.length = 0
      if obj._embedded
        for k,v of obj._embedded
          for item in v
            link = item?._links?.self?.href
            coll.push item
            if link
              enrich item, link
              item.$bind.ref = coll?.$bind?.self+'/'+link.split('/')[-1..]
              postCollMap(coll, item);
            bind item
          break
        delete obj.embedded
        Object.defineProperty coll, '$resource', configurable: true, enumerable: false, value: obj
    req = (r, params, opts, result, attached) ->
      d = deferred()
      opts ?= {}
      extend opts, defaults
      extend opts, r
      opts.headers = {}
      extend(opts.headers, defaults.headers) if defaults.headers
      extend(opts.headers, r.headers) if r.headers
      if typeof opts.data == 'string'
        extend opts.headers, { 'Content-Type': 'text/uri-list' }
      if typeof opts.data == 'object'
        extend opts.headers, { 'Content-Type': 'application/json' }
        opts.data = str opts.data, if opts.method == 'POST' then [] else attached
      if params
        sep = if opts.url.indexOf('?') == -1 then '?' else '&'
        opts.url = opts.url + sep + ((k+"="+v) for k,v of params).join("&")
      hybind.http(opts).then (data, s, r) ->
        try
          if typeof data == 'string' and data != ''
            data = JSON.parse(data)
        catch e
          d.reject e
        d.resolve result or data
      , d.reject
      promise d
    defProp = (obj, name, value) ->
      Object.defineProperty obj, name, configurable: true, enumerable: false, value: value
    postEnrich = (obj) -> obj;
    enrich = (obj, url) ->
      if not obj.$bind
         defProp obj, '$bind', ->
          args = Array.prototype.slice.call arguments
          arg = args[0]
          if typeof arg is 'object'
            target = arg
            args.shift()
          else
            prop = arg
            prev = obj[prop]?.$bind?.ref
            target = obj[prop] or obj[prop] = {}
          link = args[0]
          link = link target if typeof link is 'function'
          link = idFn target if link is undefined
          arg = args[1]
          if typeof arg is 'object'
            target = arg
            obj[prop] = target if prop
            args.shift()
          else
            prev = null
          pathOrUrl = args[1]
          pathOrUrl ?= link
          pathOrUrl = clean pathOrUrl
          ref = obj.$bind.refs?[prop] or prev or clean makeUrl selfLink(obj), pathOrUrl
          if not target.$bind
            if not pathOrUrl then throw 'No property or id specified'
            enrich target, ref
          else
            if (obj instanceof Array)
              target.$bind.ref = obj.$bind?.self+'/'+target.$bind.self.split('/')[-1..]
            else
              target.$bind.ref = ref
            target
      obj.$bind.refs = {}
      if url
        obj.$bind.ref = clean url
        obj.$bind.self ?= obj.$bind.ref
      defProp obj, '$load',  (params, opts) ->
        d = deferred()
        req {method: 'GET', url: obj.$bind.ref}, params, opts
        .then (data) ->
          if data._embedded and data._embedded[Object.keys(data._embedded)[0]] instanceof Array and not (obj instanceof Array)
            if Object.setPrototypeOf
              Object.setPrototypeOf(obj, Array.prototype)
            else
              obj.__proto__ = Array.prototype
            enrich obj
          if (obj instanceof Array)
            collMapper data, obj
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
        defProp obj, '$add',  (items, params, opts) ->
          items = [ items ] if not (items instanceof Array)
          data = (selfLink item for item in items)
          req method: 'POST', url: selfLink(obj), data: data.join('\n'), params, opts, obj
        defProp obj, '$save',  (params, opts) ->
          data = (selfLink item for item in obj)
          req method: 'PUT', url: selfLink(obj), data: data.join('\n'), params, opts, obj
        delete obj.$set
      else
        defProp obj, '$set',  (item, params, opts) ->
          item ?= obj
          req method: 'PUT', url: obj.$bind.ref, data: selfLink(item), params, opts, obj
        defProp obj, '$save',  (params, opts) ->
          if params instanceof Array
            attached = params
            params = undefined
          if opts instanceof Array
            attached = opts
            opts = undefined
          req method: 'PUT', url: selfLink(obj), data: obj, params, opts, obj, attached
        delete obj.$add
      defProp obj, '$create',  (item, params, opts) ->
        d = deferred()
        req method: 'POST', url: selfLink(obj), data: (item or {}), params, opts
        .then (data) ->
          extend(item, data) if item
          item ?= data
          enrich item, data._links.self.href
          delete item._links
          d.resolve item
        , d.reject
        promise d
      defProp obj, '$delete',  (params, opts)->
        if obj.$bind.self
          req method: 'DELETE', url: obj.$bind.self, params, opts, obj
        else
          obj.$load(params, opts).then -> req method: 'DELETE', url: obj.$bind.self, params, opts, obj
      defProp obj, '$remove',  (params, opts) ->
        req method: 'DELETE', url: obj.$bind.ref, params, opts, obj
      defProp obj, '$share',  (args...) ->
        while args.length > 0
          arg = args.shift()
          switch typeof arg
            when 'string' then prop = arg
            when 'object' then cache = arg
            when 'function' then cb = arg
        item = if prop then obj[prop] else obj
        link = selfLink item
        cache ?= defaults?.cache
        cached = cache[link]
        if prop and cached then obj[prop] = cached
        cache[link] = item if not cached
        if cb and not cached then cb item
        item
      postEnrich(obj)
    root =
      $id: (fn) -> idFn = fn
      $postEnrich: (pe) ->
        postEnrich = pe
        return
      $postCollMap: (pcm) ->
        postCollMap = pcm
        return
    enrich root, url
  hybind.http = http
  hybind
