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

testTransform = (deltaA, deltaB, aIsRemote, expected) ->
  computed = deltaB.transform(deltaA, aIsRemote)
  transformError = "Incorrect transform. Got: " + computed.toString() + ", expected: " + expected.toString()
  assert(computed.isEqual(expected), transformError)

describe('transform', ->
  it('should resolve alternating edits', ->
    deltaA = new Delta(8, 5, [new RetainOp(0, 2), new InsertOp("si"), new RetainOp(7, 8)])
    deltaB = new Delta(8, 5, [new RetainOp(0, 1), new InsertOp("e"), new RetainOp(6, 7), new InsertOp("ow")])
    expected = new Delta(5, 6, [new RetainOp(0, 1), new InsertOp("e"), new RetainOp(2, 4), new InsertOp("ow")])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(5, 6, [new RetainOp(0, 2), new InsertOp("si"), new RetainOp(3, 5)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve both clients prepending to the document', ->
    deltaA = new Delta(3, 5, [new InsertOp("aa"), new RetainOp(0, 3)])
    deltaB = new Delta(3, 5, [new InsertOp("bb"), new RetainOp(0, 3)])
    expected = new Delta(5, 7, [new RetainOp(0, 2), new InsertOp("bb"), new RetainOp(2, 5)])
    testTransform(deltaA, deltaB, true, expected)

    expected = new Delta(5, 7, [new InsertOp("aa"), new RetainOp(0, 5)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve both clients appending to the document', ->
    deltaA = new Delta(3, 5, [new RetainOp(0, 3), new InsertOp("aa")])
    deltaB = new Delta(3, 5, [new RetainOp(0, 3), new InsertOp("bb")])
    expected = new Delta(5, 7, [new RetainOp(0, 5), new InsertOp("bb")])
    testTransform(deltaA, deltaB, true, expected)

    expected = new Delta(5, 7, [new RetainOp(0, 3), new InsertOp("aa"), new RetainOp(3, 5)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve one client prepending, one client appending', ->
    deltaA = new Delta(3, 5, [new InsertOp("aa"), new RetainOp(0, 3)])
    deltaB = new Delta(3, 5, [new RetainOp(0, 3), new InsertOp("bb")])
    expected = new Delta(5, 7, [new RetainOp(0, 5), new InsertOp("bb")])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(5, 7, [new InsertOp("aa"), new RetainOp(0, 5)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve one client prepending, one client deleting', ->
    deltaA = new Delta(3, 5, [new InsertOp("aa"), new RetainOp(0, 3)])
    deltaB = new Delta(3, 1, [new RetainOp(0, 1)])
    expected = new Delta(5, 3, [new RetainOp(0, 3)])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(1, 3, [new InsertOp("aa"), new RetainOp(0, 1)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve both clients inserting to the middle', ->
    deltaA = new Delta(3, 5, [new RetainOp(0, 2), new InsertOp("aa"), new RetainOp(2, 3)])
    deltaB = new Delta(3, 4, [new RetainOp(0, 2), new InsertOp("b"), new RetainOp(2, 3)])
    expected = new Delta(5, 6, [new RetainOp(0, 2), new InsertOp("b"), new RetainOp(2, 5)])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(4, 6, [new RetainOp(0, 3), new InsertOp("aa"), new RetainOp(3, 4)])
    testTransform(deltaB, deltaA, true, expected)
  )

  it('should resolve both clients deleting from the tail', ->
    deltaA = new Delta(3, 1, [new RetainOp(0, 1)])
    deltaB = new Delta(3, 1, [new RetainOp(0, 1)])
    expected = new Delta(1, 1, [new RetainOp(0, 1)])
    testTransform(deltaA, deltaB, false, expected)
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve both clients deleting different amounts from the tail', ->
    deltaA = new Delta(3, 2, [new RetainOp(0, 2)])
    deltaB = new Delta(3, 0, [])
    expected = new Delta(2, 0, [])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(0, 0, [])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve one client deleting from the end, one from the beginning', ->
    deltaA = new Delta(3, 1, [new RetainOp(2, 3)])
    deltaB = new Delta(3, 2, [new RetainOp(0, 2)])
    expected = new Delta(1, 0, [])
    testTransform(deltaA, deltaB, false, expected)

    expected = new Delta(2, 0, [])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve one client deleting from the end, one from the beginning', ->
    deltaA = new Delta(5, 3, [new RetainOp(2, 5)])
    deltaB = new Delta(5, 3, [new RetainOp(0, 3)])
    expected = new Delta(3, 1, [new RetainOp(0, 1)])
    testTransform(deltaA, deltaB, false, expected)
    expected = new Delta(3, 1, [new RetainOp(2, 3)])
    testTransform(deltaB, deltaA, false, expected)
  )

  it('should resolve this fuzzer test we once failed', ->
    deltaA = new Delta(3, 25, [new RetainOp(0, 1), new InsertOp("fpwqyakxrbhdjcxvbepmkm"), new RetainOp(1, 3)])
    deltaB = new Delta(3, 43, [new RetainOp(0, 1), new InsertOp("xqmxjiaykkzheizgdsnjixosvqbqkyorcfwafaqax"), new RetainOp(2, 3)])
    expected = new Delta(25, 65, [new RetainOp(0, 1), new InsertOp("xqmxjiaykkzheizgdsnjixosvqbqkyorcfwafaqax"), new RetainOp(1, 23), new RetainOp(24, 25)])
    testTransform(deltaA, deltaB, false, expected)
    expected = new Delta(43, 65, [new RetainOp(0, 1), new InsertOp("fpwqyakxrbhdjcxvbepmkm"), new RetainOp(1, 43)])
    testTransform(deltaB, deltaA, false, expected)
  )
)
