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

describe('compact', ->
  it('should coalesce adjacent inserts with no attributes', ->
    delta = new Delta(0, 4, [new InsertOp("ab"), new InsertOp("cd")])
    expected = new Delta(0, 4, [new InsertOp("abcd")])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should coalesce adjacent inserts with matching attributes', ->
    delta = new Delta(0, 4, [new InsertOp("ab", {bold: true}), new InsertOp("cd", {bold: true})])
    expected = new Delta(0, 4, [new InsertOp("abcd", {bold: true})])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should not coalesce adjacent inserts with mismatching attributes', ->
    delta = new Delta(0, 4, [new InsertOp("ab"), new InsertOp("cd", {bold: true})])
    expected = new Delta(0, 4, [new InsertOp("ab"), new InsertOp("cd", {bold: true})])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should coalesce continuous, adjacent retains', ->
    delta = new Delta(4, 4, [new RetainOp(0, 2), new RetainOp(2, 4)])
    expected = new Delta(4, 4, [new RetainOp(0, 4)])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should not coalesce continuous, adjacent retains with mismatched attrs', ->
    delta = new Delta(4, 4, [new RetainOp(0, 2), new RetainOp(2, 4, {bold: true})])
    expected = new Delta(4, 4, [new RetainOp(0, 2), new RetainOp(2, 4, {bold: true})])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should not coalesce discontinuous, adjacent retains ', ->
    delta = new Delta(5, 4, [new RetainOp(0, 2), new RetainOp(3, 5)])
    expected = new Delta(5, 4, [new RetainOp(0, 2), new RetainOp(3, 5)])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )

  it('should not coalesce an insert adjacent to a retain', ->
    delta = new Delta(2, 4, [new RetainOp(0, 2), new InsertOp("ab")])
    expected = new Delta(2, 4, [new RetainOp(0, 2), new InsertOp("ab")])
    delta.compact()
    console.assert(delta.isEqual(expected))
  )
)
