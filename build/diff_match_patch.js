/*! Tandem Core - v0.4.6 - 2013-12-13
 *  https://www.stypi.com/
 *  Copyright (c) 2013
 *  Jason Chen, Salesforce.com
 *  Byron Milligan, Salesforce.com
 */

(function() {
  var googlediff;

  googlediff = require('googlediff');

  googlediff.DIFF_DELETE = -1;

  googlediff.DIFF_INSERT = 1;

  googlediff.DIFF_EQUAL = 0;

  module.exports = googlediff;

}).call(this);
