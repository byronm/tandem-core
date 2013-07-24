Op = require('./op')


# Used to represent retains in the delta. [inclusive, exclusive)
class RetainOp extends Op
  @isRetain: (r) ->
    return r? && typeof r.start == "number" && typeof r.end == "number"

  constructor: (@start, @end, attributes = {}) ->
    @attributes = _.clone(attributes)

  getAt: (start, length) ->
    return new RetainOp(@start + start, @start + start + length, @attributes)

  getLength: ->
    return @end - @start

  isEqual: (other) ->
    return other? and @start == other.start and @end == other.end and _.isEqual(@attributes, other.attributes)

  split: (offset) ->
    left = new RetainOp(@start, @start + offset, @attributes)
    right = new RetainOp(@start + offset, @end, @attributes)
    return [left, right]

  toString: ->
    return "{{#{@start} - #{@end}), #{this.printAttributes()}}"


module.exports = RetainOp
