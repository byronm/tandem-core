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

assert = require('chai').assert

Tandem = require('../index')
Delta      = Tandem.Delta
InsertOp   = Tandem.InsertOp
RetainOp   = Tandem.RetainOp

describe('invert', ->
  testInverse = (deltaA, deltaB) ->
    inverse = deltaA.invert(deltaB)
    assert(((deltaA.compose(deltaB)).compose(inverse)).isEqual(deltaA))

  it('should handle deleting the document', ->
    deltaA = new Delta(0, 1, [new InsertOp("a")])
    deltaB = new Delta(1, 0, [])
    inverse = deltaA.invert(deltaB)
    expectedInverse = new Delta(0, 1, [new InsertOp("a")])
    assert(inverse.isEqual(expectedInverse),
      "Expected: #{expectedInverse} but got: #{inverse}")
  )

  it('should handle deleting the head of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 2, [new RetainOp(1, 3)])
    testInverse(deltaA, deltaB)
  )

  it('should handle deleting the tail of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 1, [new RetainOp(0, 1)])
    expectedInverse = new Delta(1, 3, [new RetainOp(0, 1), new InsertOp("bc")])
    inverse = deltaA.invert(deltaB)
    assert(((deltaA.compose(deltaB)).compose(inverse)).isEqual(deltaA))
  )

  it('should handle deleting the middle of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 2, [new RetainOp(0, 1), new RetainOp(2, 3)])
    testInverse(deltaA, deltaB)
  )

  it('should handle inserting the entire document', ->
    deltaA = new Delta(0, 0, [])
    deltaB = new Delta(0, 3, [new InsertOp("abc")])
    testInverse(deltaA, deltaB)
  )

  it('should handle prepending to the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 4, [new InsertOp("1"), new RetainOp(0, 3)])
    testInverse(deltaA, deltaB)
  )

  it('should handle appending to the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 4, [new RetainOp(0, 3), new InsertOp("d")])
    testInverse(deltaA, deltaB)
  )

  it('should handle inserting to the middle of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 5, [new RetainOp(0, 1),
                              new InsertOp("12"),
                              new RetainOp(1, 3)])
    testInverse(deltaA, deltaB)
  )

  it('should handle replacing the entire document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new InsertOp("123")])
    testInverse(deltaA, deltaB)
  )

  it('should handle replacing the head of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new InsertOp("1"), new RetainOp(1, 3)])
    testInverse(deltaA, deltaB)
  )

  it('should handle replacing the tail of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new RetainOp(0, 2), new InsertOp("1")])
    testInverse(deltaA, deltaB)
  )

  it('should handle replacing the middle of the document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new RetainOp(0, 1),
                              new InsertOp("1"),
                              new RetainOp(2, 3)])
    testInverse(deltaA, deltaB)
  )
)
