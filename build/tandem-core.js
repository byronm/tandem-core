(function() {
  module.exports = {
    Delta: require('./delta'),
    DeltaGen: require('./delta_generator'),
    Op: require('./op'),
    InsertOp: require('./insert'),
    RetainOp: require('./retain')
  };

}).call(this);
