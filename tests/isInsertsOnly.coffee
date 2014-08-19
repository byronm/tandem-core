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

describe('isInsertsOnly', ->
  it('should accept deltas with a single insert op', ->
    delta = new Delta(0, 3, [new InsertOp("abc")])
    assert(delta.isInsertsOnly())
  )

  it('should reject deltas with a single retain op', ->
    delta = new Delta(0, 3, [new RetainOp(0, 3)])
    assert(!delta.isInsertsOnly())
  )

  it('should reject deltas with multiple retain ops', ->
    delta = new Delta(0, 6, [new RetainOp(1, 4), new RetainOp(6, 9)])
    assert(!delta.isInsertsOnly())
  )

  it('should reject deltas with inserts and retains', ->
    delta = new Delta(0, 6, [new RetainOp(0, 3), new InsertOp("abc")])
    assert(!delta.isInsertsOnly())
  )
)
