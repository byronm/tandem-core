GLOBAL._  = require('underscore')._
Tandem    = process.env.TANDEM_COV ? require('./src-js/tandem') : require('./src/tandem')

module.exports = Tandem
