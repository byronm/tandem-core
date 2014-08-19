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


class RetainOp extends Op
  # (@start, @end) is [inclusive, exclusive)
  constructor: (@start, @end, attributes = {}) ->
    @attributes = _.clone(attributes)

  getAt: (start, length) ->
    return new RetainOp(@start + start, @start + start + length, @attributes)

  getLength: ->
    return @end - @start

  isEqual: (other) ->
    return other? and @start == other.start and @end == other.end and
      _.isEqual(@attributes, other.attributes)

  split: (offset) ->
    left = new RetainOp(@start, @start + offset, @attributes)
    right = new RetainOp(@start + offset, @end, @attributes)
    return [left, right]

  toString: ->
    return "{{#{@start} - #{@end}), #{this.printAttributes()}}"


module.exports = RetainOp
