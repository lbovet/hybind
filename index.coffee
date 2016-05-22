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
) this, (extend, q, request) ->
  selfLink = (obj) -> obj._links.self
  makeUrl = (baseUrl, pathOrUrl) ->
    baseUrl += '/' if baseUrl[-1..] != '/'
    if pathOrUrl.indexOf(':') == -1 then baseUrl + pathOrUrl else pathOrUrl
  enrich = (obj, url) ->
    if url
      obj._links =
        self: url
    obj.$declare = (link, pathOrUrl) ->
      pathOrUrl ?= link
      obj[link] = {}
      enrich obj[link], makeUrl selfLink(obj), pathOrUrl
    obj
  hybind = (url) ->
    enrich {}, url
  hybind.extend = extend
  hybind.request = request
  hybind.q = q
  hybind
