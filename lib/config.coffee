_        = require 'underscore'
cheerio  = require 'cheerio'
utils    = require './parse_utils'
messages = require './messages'

# parser configuration
module.exports =

  exportColumns: [
    'PRODUCT'
    'OBJECT_TYPE'
    'OBJECT_NAME'
    'ATTRIBUTE_NAME'
    'DIFFERENCE'
    'COMMENT'
    'SOURCE'
  ]
  allow:     
    changes: [
      {
        pattern: '.*attribute.*changes.*between'
        synonym: messages.attributeChange
      },
      { 
        pattern: '.*removed.*in.*'
        synonym: messages.objectRemoved
      }
    ]

  ignore:
    objectType: [
      'indexes'
      'partitioned tables'
      'queue tables'
      'materialized view logs'
    ]
    descriptions: [
      'click here'
    ]

  changeTestPatterns: [
    'procFuncArg'
    'procFuncType'
    'columnChange'
    'commonChanges'
    'tableChanges'
    'tableName'
    'viewChange'
    'funcReturn'
    'objectRemoved'
  ]

  regex:
    files: 
      pattern: ".*_diff\\.html" 

    commonChanges:
      # other detectable changes: order_flag|initial_extent|max_value
      pattern: "(cache_size|index_type|increment_by):(.*)=>(.*)" 
      parse: (source) ->
        return if (RegExp.$1 == 'cache_size' || RegExp.$1 == 'max_value') && Number(RegExp.$2) < Number(RegExp.$3)
        {desc: source}   

    objectRemoved:
      pattern: "(proc-|func-|col-)([\\w\(\)]*)$"
      parse: (source) ->
        {desc: RegExp.$1 + RegExp.$2, attribute: RegExp.$2}   

    viewChange:
      pattern: "^text:(.*)=>(.*)"
      parse: (source) ->
        {desc: source}   


    tableName:
      pattern: "table_name:(.*)=>(.*)"
      parse: (source) ->
        {desc: source}   

    tableChanges:
      pattern: "tab-([\\w\(\)]*):(column_position|column_usage):(.*)=>(.*)"
      parse: (source) ->
        {desc: source, attribute: RegExp.$1}    

    columnChange:
      # other detectable changes: data_scale|data_precision|column_id
      pattern: "col-([\\w\(\)]*):(data_type|nullable|char_length):(.*)\\s*=>\\s*(.*)" 
      parse: (source) ->
        return if RegExp.$2 == 'char_length' && Number(RegExp.$3) < Number(RegExp.$4)
        return if RegExp.$2 == 'nullable' && RegExp.$3.match(/n/i)
        
        #TODO: replace header with message about column change
        #Risk: reaction of CEMLI scanner is unknown
        header: messages.attributesChangeMessage
        desc: RegExp.$2 + ':' + RegExp.$3 + '=>' + RegExp.$4
        attribute: RegExp.$1

    funcReturn:
      pattern: "func-([\\w\(\)]*):return_type:(.*)=>(.*)"
      parse: (source) ->
        header: messages.attributesChangeMessage
        desc: 'return_type:' + RegExp.$2 + '=>' + RegExp.$3
        attribute: RegExp.$1

    procFuncType:
      pattern: "(proc-|func-)([\\w\(\)]*):arg:([\\w\(\)]*):(data_type|in_out):(.*)=>(.*)"
      parse: (source) ->
        header: messages.attributesChangeMessage
        desc: 'arg:' + RegExp.$3 + ':' + RegExp.$4 + ':' + RegExp.$5 + '=>' + RegExp.$6
        attribute: RegExp.$2

    procFuncArg:
      pattern: "(proc-|func-)([\\w\(\)]*):arg:([\\w\(\)]*):(added|removed).*"
      parse: (source) ->
        header: messages.attributesChangeMessage
        desc: 'arg:' + RegExp.$3 + '-' + RegExp.$4
        attribute: RegExp.$2

    module:
      data: (source) ->
        source('p').first().text()
      pattern: "Product:(.*)"      
      parse: ->
        {module: RegExp.$1}

    versions: 
      data: (source) ->
        [
          source('table tr').first().find('td').last().text(),
          source('p').last().text()
        ]        
      pattern: ".*difference.*between.*(\\d{2}\\.\\d{1,2}\\.\\d{1,2}).*and.*(\\d{2}\\.\\d{1,2}\\.\\d{1,2}).*"      
      parse: ->
        {to: RegExp.$1, from: RegExp.$2}

    changes:
      data: (source) ->
        self = module.exports

        result = []
        source('table').each (index, elem) ->
          objectType = source(elem).find('tr').first().find('td').first().text()
          
          return if utils.testPatterns(objectType, self.ignore.objectType)

          source(elem).find('tr').each (trIndex, tr) ->
            
            return if trIndex == 0             
            tds = source(tr).find('td')   
            objectName = tds.first().text()
            sourceCode = tds.last().text()

            tds.last().find('div').each (divIndex, div) ->
              listOfChanges = _.without String(source(div).html()).split('<br>'), ''

              change = source(_.first(listOfChanges)).text() || _.first(listOfChanges)
              changeInfo    = utils.synonym(change, self.allow.changes)

              return unless utils.testPatterns(change, _.map(self.allow.changes, (el)->el.pattern))

              
              listOfChanges =  _.rest(listOfChanges)

              defaultResult = (description) ->
                objectType: objectType
                objectName: objectName
                attribute: null
                change: changeInfo
                desc: description
                source: sourceCode
                

              if _.isEmpty listOfChanges
                changes = [defaultResult(changeInfo)]
              else
                changes = []
              
              attrInfo = {}

              _.each listOfChanges, (listItem) ->
                desc = source(listItem).text()
                return if !desc || utils.testPatterns(desc, self.ignore.descriptions)

                for pattern in self.changeTestPatterns

                  changeData = utils.testRegex(desc, self.regex[pattern])                  
                  continue unless changeData.detected

                  #console.log desc, pattern

                  coreData = defaultResult(changeInfo) 
                  attr = changeData.attribute

                  if changeData.attribute
                    if attrInfo[attr]
                      #TODO: detailed information about attributes can be extracted here
                      # current implementation simply groups all entries with the same attribute
                      attrInfo[attr].desc += "\n" + changeData.desc
                    else
                      attrInfo[attr] = _.extend coreData, changeData 
                      if changeData.header
                        attrInfo[attr].desc = changeData.header + "\n" + changeData.desc
                  else
                    changes.push _.extend coreData, changeData

              result = _.union result, changes, _.values attrInfo

        result



