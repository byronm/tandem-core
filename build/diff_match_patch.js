(function() {
  var googlediff;

  googlediff = require('googlediff');

  googlediff.DIFF_DELETE = -1;

  googlediff.DIFF_INSERT = 1;

  googlediff.DIFF_EQUAL = 0;

  module.exports = googlediff;

}).call(this);
