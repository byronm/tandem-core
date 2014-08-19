# Copyright (c) 2012, Salesforce.com, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.  Redistributions in binary
# form must reproduce the above copyright notice, this list of conditions and
# the following disclaimer in the documentation and/or other materials provided
# with the distribution.  Neither the name of Salesforce.com nor the names of
# its contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.

_  = require('lodash')
Op = require('./op')


class InsertOp extends Op
  constructor: (@value, attributes = {}) ->
    @attributes = _.clone(attributes)

  getAt: (start, length) ->
    return new InsertOp(@value.substr(start, length), @attributes)

  getLength: ->
    return @value.length

  isEqual: (other) ->
    return other? and @value == other.value and
      _.isEqual(@attributes, other.attributes)

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
