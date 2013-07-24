Op = require('./op')


class InsertOp extends Op
  @isInsert: (i) ->
    return i? && typeof i.value == "string"

  constructor: (@value, attributes = {}) ->
    @attributes = _.clone(attributes)

  getAt: (start, length) ->
    return new InsertOp(@value.substr(start, length), @attributes)

  getLength: ->
    return @value.length

  isEqual: (other) ->
    return other? and @value == other.value and _.isEqual(@attributes, other.attributes)

  join: (other) ->
    if _.isEqual(@attributes, other.attributes)
      return new InsertOp(@value + second.value, @attributes)
    else
      throw Error

  split: (offset) ->
    left = new InsertOp(@value.substr(0, offset), @attributes)
    right = new InsertOp(@value.substr(offset), @attributes)
    return [left, right]

  toString: ->
    return "{#{@value}, #{this.printAttributes()}}"


module.exports = InsertOp
