# support files
messages  = require('./lib/messages')
parser    = require('./lib/parser')
config    = require('./lib/config')
utils     = require('./lib/parse_utils')

#libraries
csv       = require('csv')
async     = require('async')
_         = require('underscore')
fs        = require('fs')
argv      = require('optimist')
          .usage(messages.help)
          .demand('f')
          .alias('f', 'folder')
          .describe('f', messages.noDestinationFolder)
          .argv


start = process.hrtime()

path = argv.f

unless fs.existsSync(path)
  console.log messages.pathDoesNotExist
else

  # DEBUG with -d. Comparison with previously obtained results.
  # Assumption: there are only two result files in the directory: old and new
  if argv.d
    results = []
    fs.readdir path, (err, files) ->
      async.each files, (filename, callback) ->
        if filename.match(/.*result.*\.csv$/i)
          csv()
            .from.path([path, filename].join('/'), { delimiter: ',', escape: '"' })
            .to.array (data) ->

              groupData = _.countBy _.rest(data), (el) -> el[0]
              sortedKeys = _.sortBy _.keys(groupData), (el) -> el
              result = {name: filename}
              for key in sortedKeys
                result[key] = groupData[key]
              results.push result
              callback()
        else
          callback()
      , ->

        if results.length == 2 
          sorted = _.sortBy results, (el) -> _.keys(el).length
          result = {}
          for key, value1 of sorted[1]
            value0 = sorted[0][key]
            if value0 != value1
              result[key] = [value1, value0].join('=>')
          console.log result

    return

  results = {}

  fs.readdir path, (err, files) ->
        
    async.each files, (filename, callback) ->
      if utils.testRegex(filename, config.regex.files).detected
        
        fs.readFile [path, filename].join('/'), (err,data) ->
          if err
            callback()
            console.log(messages.errorReadingFile, filename)
          else
            parser.loadModuleChanges data, (changes) -> 

              if changes
                version = [changes.to, changes.from].join('_')
                results[version] ||= [config.exportColumns]
                results[version] = _.union results[version], changes.table
              callback()        
      else
        callback()
    , ->
      if _.isEmpty(results)
        console.log messages.noFiles
      else
        
        for version, changes of results
          console.log messages.parsingComplete
            .replace("$0", changes.length)
            .replace("$1", version)
            .replace("$2", process.hrtime(start)[0])
          csv().from(changes).to path + '/results_' + version + '.csv'

        

  
