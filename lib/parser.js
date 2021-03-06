// Generated by CoffeeScript 1.4.0
(function() {
  var cheerio, config, utils, _;

  cheerio = require('cheerio');

  _ = require('underscore');

  config = require('./config');

  utils = require('./parse_utils');

  module.exports = {
    loadModuleChanges: function(data, callback) {
      var $, changes, module, result, table, version;
      $ = cheerio.load(data);
      module = utils.testRegex($, config.regex.module);
      version = utils.testRegex($, config.regex.versions);
      changes = utils.testRegex($, config.regex.changes);
      if (module.detected && version.detected && changes.detected) {
        table = [];
        _.each(changes.result, function(change) {
          return table.push(_.union([module.module], _.values(change)));
        });
        result = _.extend({}, version, {
          table: table
        });
      }
      return callback(result);
    }
  };

}).call(this);
