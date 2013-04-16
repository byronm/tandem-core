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
