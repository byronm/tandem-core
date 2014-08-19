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

_         = require('lodash')
expect    = require('chai').expect

Tandem    = require('../index')
Delta     = Tandem.Delta
InsertOp  = Tandem.InsertOp
RetainOp  = Tandem.RetainOp


class StringEditor
  constructor: (@text = "") ->

  insert: (index, text) ->
    @text = @text.slice(0, index) + text + @text.slice(index)

  delete: (index, length) ->
    @text = @text.slice(0, index) + @text.slice(index + length)

  format: ->


tests = [{
  name: 'should insert text'
  start: 'Hello'
  delta: new Delta(5, 12, [
    new RetainOp(0, 5)
    new InsertOp(' World!')
  ])
  expected: 'Hello World!'
}, {
  name: 'should delete text'
  start: 'Hello World!'
  delta: new Delta(12, 5, [
    new RetainOp(0, 5)
  ])
  expected: 'Hello'
}]


describe('apply', ->
  _.each(tests, (test) ->
    it(test.name, ->
      editor = new StringEditor(test.start)
      test.delta.apply(editor.insert, editor.delete, editor.format, editor)
    )
  )
)
