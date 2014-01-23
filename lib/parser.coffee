# parser

cheerio = require 'cheerio'
_       = require 'underscore'

config  = require './config'
utils  = require './parse_utils'

module.exports = 

  loadModuleChanges: (data, callback) ->
    $ = cheerio.load(data)
    
    module  = utils.testRegex($, config.regex.module)
    version = utils.testRegex($, config.regex.versions)
    changes = utils.testRegex($, config.regex.changes)
   
    if module.detected && version.detected && changes.detected
      table = []
      _.each changes.result, (change) ->
        table.push _.union [module.module], _.values(change)

      result = _.extend {}, version, {table: table}

    callback result





