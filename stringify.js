/**
 * Copyright (c) 2008-2012 Remy Sharp, http://jsbin.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * Stringify.
 * Inspect native browser objects and functions.
 */
var stringify = (function () {

  var sortci = function(a, b) {
    return a.toLowerCase() < b.toLowerCase() ? -1 : 1;
  };

  var htmlEntities = function (str) {
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  };

  /**
   * Recursively stringify an object. Keeps track of which objects it has
   * visited to avoid hitting circular references, and a buffer for indentation.
   * Goes 2 levels deep.
   */
  return function stringify(o, visited, buffer) {
    var i, vi, type = '', parts = [], circular = false;
    buffer = buffer || '';
    visited = visited || [];

    // Get out fast with primitives that don't like toString
    if (o === null) {
      return 'null';
    }
    if (typeof o === 'undefined') {
      return 'undefined';
    }

    // Determine the type
    try {
      type = ({}).toString.call(o);
    } catch (e) { // only happens when typeof is protected (...randomly)
      type = '[object Object]';
    }

    // Handle the primitive types
    if (type == '[object Number]') {
      return ''+o;
    }
    if (type == '[object Boolean]') {
      return o ? 'true' : 'false';
    }
    if (type == '[object Function]') {
      return "[object Function]";
    }
    if (type == '[object String]') {
      return '"' + htmlEntities(o.replace(/"/g, '\\"')) + '"';
    }

    // Check for circular references
    for (vi = 0; vi < visited.length; vi++) {
      if (o === visited[vi]) {
        // Notify the user that a circular object was found and, if available,
        // show the object's outerHTML (for body and elements)
        return '[circular ' + type.slice(1) +
          ('outerHTML' in o ? ' :\n' + htmlEntities(o.outerHTML).split('\n').join('\n' + buffer) : '')
      }
    }

    // Remember that we visited this object
    visited.push(o);

    // Stringify each member of the array
    if (type == '[object Array]') {
      for (i = 0; i < o.length; i++) {
        parts.push(stringify(o[i], visited, buffer+'  '));
      }
      return '[' + parts.join(', ') + ']';
    }

    // Fake array – very tricksy, get out quickly
    if (type.match(/Array/)) {
      return type;
    }

    var typeStr = type + ' ',
        newBuffer = buffer + '  ';

    // Dive down if we're less than 2 levels deep
    if (buffer.length / 2 < 10) {

      var names = [];
      // Some objects don't like 'in', so just skip them
      try {
        for (i in o) {
          names.push(i);
        }
      } catch (e) {}

      names.sort(sortci);
      for (i = 0; i < names.length; i++) {
        try {
          parts.push(newBuffer + names[i] + ': ' + stringify(o[names[i]], visited, newBuffer));
        } catch (e) {}
      }

    }

    // If nothing was gathered, return empty object
    if (!parts.length) return '{}';

    // Return the indented object with new lines
    return '{\n' + parts.join(',\n') + '\n' + buffer + '}';
  };
}());
