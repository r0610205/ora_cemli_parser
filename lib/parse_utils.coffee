_       = require 'underscore'

module.exports = 

  synonym: (text, lookup) ->
    result = text
    _.each lookup, (elem) ->
      if text.match RegExp(elem.pattern, 'gim')
        result = elem.synonym

    result

  testPatterns: (text, patterns) ->
    result = false
    _.each _.toArray(patterns), (elem) ->
      result ||= text.match RegExp(elem, 'gim')
    result

  testRegex: (fn, tmpl) ->

    result = {detected: false}

    return result unless _.isObject tmpl

    source = if _.isFunction tmpl.data then tmpl.data(fn) else fn
    source = [source] unless _.isArray(source)


    unless tmpl.pattern
      result.detected = source && source.length > 0
      result.result = source
    else
      _.each source, (elem) ->        
        
        if elem.match RegExp(tmpl.pattern, tmpl.options || "gim")
          result.detected = true
          if _.isFunction tmpl.parse
            parsedData = tmpl.parse(elem)
            if parsedData
              _.extend result, parsedData
            else
              result.detected = false

    result