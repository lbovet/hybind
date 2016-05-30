((root, factory) ->
  if typeof define == 'function' and define.amd # AMD
    define [ 'lodash', 'q', 'request' ], factory
  else if typeof module == 'object' and module.exports # Node
    module.exports = factory(require('lodash').extend, require('q'), require('request'))
  else if root.angular
    root.angular.module('hybind', []).factory 'api', ['$q', '$http',
     (q, http) ->
       factory angular.extend, $q, $http
    ]
  else
    root.hybind = factory(root._?.extend, root.Q, root.request)
) this, (extend, Q, request) ->
  selfLink = (obj) -> obj?._links?.self?.href
  stringify = (obj) -> JSON.stringify obj, (k,v) -> v if k != '_links'
  makeUrl = (baseUrl, pathOrUrl) ->
    baseUrl += '/' if baseUrl[-1..] != '/'
    if pathOrUrl.indexOf(':') == -1 then baseUrl + pathOrUrl else pathOrUrl
  hybind = (url) ->
    idFn = ->
      throw 'No id function defined'
    collMapper = (obj, coll) ->
      coll.length = 0
      if obj._embedded
        for k,v of obj._embedded
          for item in v
            coll.push item
            link = selfLink item
            enrich item, link if link
          break
    enrich = (obj, url) ->
      if url
        obj._links = self: href: url
      obj.$bind = ->
        args = Array.prototype.slice.call(arguments);
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
      obj.$load = ->
        d = Q.defer()
        hybind.request
          method: 'GET', uri: selfLink obj
        .then (data) ->
          if (obj instanceof Array)
            collMapper data, obj
          else
            for prop of obj
              if prop.indexOf('_') != 0 and typeof obj[prop] != 'function'
                delete obj[prop]
            hybind.extend obj, data
            if data?._links
              for name, link of data._links
                if name != 'self'
                  p = obj[name] = {}
                  obj.$bind p, link.href
          d.resolve obj
        d.promise
      obj.$save = ->
        d = Q.defer()
        hybind.request
          method: 'PUT', uri: selfLink(obj), data: stringify(obj)
        .then d.resolve
        d.promise
      obj.$delete = ->
        d = Q.defer()
        hybind.request
          method: 'DELETE', uri: selfLink obj
        .then d.resolve
        d.promise
      removeLink = selfLink obj
      obj.$remove = ->
        d = Q.defer()
        hybind.request
          method: 'DELETE', uri: removeLink
        .then d.resolve
        d.promise
      obj
    root =
      $id: (fn) ->
        idFn = fn
    enrich root, url
  hybind.extend = extend
  hybind.request = request
  hybind.q = Q
  hybind
