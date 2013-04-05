assert = require('chai').assert

Tandem = require('../index')
Delta      = Tandem.Delta
InsertOp   = Tandem.InsertOp
RetainOp   = Tandem.RetainOp
DeltaGen   = Tandem.DeltaGen

testDeleteAt = (delta, deletionPoint, numToDelete, expected) ->
  DeltaGen.deleteAt(delta, deletionPoint, numToDelete, length)
  assert(delta.isEqual(expected))

describe('DeltaGen', ->
  describe('deleteAt', ->
    it('should delete 1 from the middle of the retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 3, 1)
      expected = delta.isEqual(new Delta(0, 5, [new RetainOp(0, 3),
                                                new RetainOp(4, 6)]))
      assert(delta.isEqual(expected))
    )

    it('should delete 2 from the middle of the retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 3, 2)
      expected = new Delta(0, 4, [new RetainOp(0, 3), new RetainOp(5, 6)])
      assert(delta.isEqual(expected))
    )

    it('should delete the end of the of the retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 5, 1)
      expected = new Delta(0, 5, [new RetainOp(0, 5)])
      assert(delta.isEqual(expected))
    )

    it('should handle deleting beyond the end of the retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 5, 2)
      expected = new Delta(0, 5, [new RetainOp(0, 5)])
      assert(delta.isEqual(expected))
    )

    it('should delete 1 from the start of the retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 0, 1)
      expected = new Delta(0, 5, [new RetainOp(1, 6)])
      assert(delta.isEqual(expected))
    )

    it('should delete the entire retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 6)])
      DeltaGen.deleteAt(delta, 0, 6)
      expected = new Delta(0, 0, [])
      assert(delta.isEqual(expected))
    )

    it('should delete 1 from start of the insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.deleteAt(delta, 0, 1)
      expected = new Delta(0, 5, [new InsertOp("12345")])
      assert(delta.isEqual(expected))
    )

    it('should delete many from the start of the insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.deleteAt(delta, 0, 4)
      expected = new Delta(0, 2, [new InsertOp("45")])
      assert(delta.isEqual(expected))
    )

    it('should delete 1 from the middle of the insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.deleteAt(delta, 3, 1)
      expected = new Delta(0, 5, [new InsertOp("01245")])
      assert(delta.isEqual(expected))
    )

    it('should delete many from the end of the insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.deleteAt(delta, 3, 3)
      assert(delta.isEqual(new Delta(0, 3, [new InsertOp("012")])))
    )

    it('should delete 1 from the end of the insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.deleteAt(delta, 5, 1)
      expected = new Delta(0, 5, [new InsertOp("01234")])
      assert(delta.isEqual(expected))
    )

    it('should delete many spanning a retain, insert', ->
      delta = new Delta(0, 6, [new RetainOp(0, 3), new InsertOp("abc")])
      DeltaGen.deleteAt(delta, 2, 3)
      expected = new Delta(0, 3, [new RetainOp(0, 2), new InsertOp("c")])
      assert(delta.isEqual(expected))
    )

    it('should delete many spanning adjacent retains', ->
      delta = new Delta(0, 6, [new RetainOp(0, 3), new RetainOp(6, 9)])
      DeltaGen.deleteAt(delta, 2, 3)
      expected = new Delta(0, 3, [new RetainOp(0, 2), new RetainOp(8, 9)])
      assert(delta.isEqual(expected))
    )

    it('should delete an entire retain preceding an adjacent retain', ->
      delta = new Delta(0, 6, [new RetainOp(0, 3), new RetainOp(6, 9)])
      DeltaGen.deleteAt(delta, 0, 3)
      expected = new Delta(0, 3, [new RetainOp(6, 9)])
      assert(delta.isEqual(expected))
    )

    it('should delete many spanning adjacent inserts', ->
      delta = new Delta(0, 6, [new InsertOp("abc"), new InsertOp("efg")])
      DeltaGen.deleteAt(delta, 2, 3)
      expected = new Delta(0, 3, [new InsertOp("ab"), new InsertOp("g")])
      assert(delta.isEqual(expected))
    )

    it('should delete many spanning an insert, retain', ->
      delta = new Delta(0, 6, [new InsertOp("abc"), new RetainOp(3, 6)])
      DeltaGen.deleteAt(delta, 2, 3)
      expected = new Delta(0, 3, [new InsertOp("ab"), new RetainOp(5, 6)])
      assert(delta.isEqual(expected))
    )

    it('should many spanning 3 retains', ->
      delta = new Delta(37, 28, [new RetainOp(0, 21),
                                 new RetainOp(24, 26),
                                 new RetainOp(32, 37)])
      DeltaGen.deleteAt(delta, 12, 14)
      expected = new Delta(37, 14, [new RetainOp(0, 12), new RetainOp(35, 37)])
      assert(delta.isEqual(expected))
    )
  )

  describe('insertAt', ->
    it('should write many into middle of insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.insertAt(delta, 3, "abcdefg")
      expected = new Delta(0, 13, [new InsertOp("012abcdefg345")])
      assert(delta.isEqual(expected))
    )

    it('should write many to start of insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.insertAt(delta, 0, "abcdefg")
      expected = new Delta(0, 13, [new InsertOp("abcdefg012345")])
      assert(delta.isEqual(expected))
    )

    it('should write many to end of insert', ->
      delta = new Delta(0, 6, [new InsertOp("012345")])
      DeltaGen.insertAt(delta, 6, "abcdefg")
      expected = new Delta(0, 13, [new InsertOp("012345abcdefg")])
      assert(delta.isEqual(expected))
    )
  )

  describe('formatAt', ->
    it('should remove italics on the first insert and ignore the second', ->
      reference = new Delta(0, 6, [new InsertOp("abc", {italic: true}),
                                   new InsertOp("def", {})])
      delta = new Delta(6, 6, [new RetainOp(0, 6)])
      DeltaGen.formatAt(delta, 0, 5, ["italic"], reference)
      expected = new Delta(6, 6, [new RetainOp(0, 3, {italic: null}),
                                  new RetainOp(3, 6)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove italics on the first insert and ignore the second', ->
      reference = new Delta(0, 6, [new InsertOp("abc", {italic: true}),
                                   new InsertOp("def", {})])
      delta = new Delta(6, 6, [new RetainOp(0, 6)])
      DeltaGen.formatAt(delta, 1, 3, ["italic"], reference)
      expected = new Delta(6, 6, [new RetainOp(0, 1),
                                  new RetainOp(1, 3, {italic: null}),
                                  new RetainOp(3, 6)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold from the 0th character', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 0, 1, ["bold"], reference)
      expected = new Delta(3, 6, [new InsertOp("a"),
                                  new InsertOp("bc", {bold: true}),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold and add italic to the 0th character', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 0, 1, ["bold", "italic"], reference)
      expected = new Delta(3, 6, [new InsertOp("a", {italic: true}),
                                  new InsertOp("bc", {bold: true}),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold from first two characters', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 0, 2, ["bold"], reference)
      expected = new Delta(3, 6, [new InsertOp("ab"),
                                  new InsertOp("c", {bold: true}),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should and add italic to the first two characters', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 0, 2, ["bold", "italic"], reference)
      expected = new Delta(3, 6, [new InsertOp("ab", {italic: true}),
                                  new InsertOp("c", {bold: true}),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold from the middle characters', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 1, 2, ["bold"], reference)
      expected = new Delta(3, 6, [new InsertOp("a", {bold: true}),
                                  new InsertOp("bc"),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold and add italic to the middle chars', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 1, 2, ["bold", "italic"], reference)
      expected = new Delta(3, 6, [new InsertOp("a", {bold: true}),
                                  new InsertOp("bc", {italic: true}),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )

    it('should remove bold from the last char in insert', ->
      reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
      delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}),
                               new RetainOp(0, 3)])
      DeltaGen.formatAt(delta, 2, 1, ["bold"], reference)
      expected = new Delta(3, 6, [new InsertOp("ab", {bold: true}),
                                  new InsertOp("c"),
                                  new RetainOp(0, 3)])
      assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
    )
  )

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 2, 1, ["bold", "italic"], reference)
expected = new Delta(3, 6, [new InsertOp("ab", {bold: true}), new InsertOp("c", {italic: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 3, ["italic"], reference)
expected = new Delta(3, 6, [new InsertOp("abc", {bold: true, italic: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 2, 1, ["italic"], reference)
expected = new Delta(3, 6, [new InsertOp("ab", {bold: true}), new InsertOp("c", {bold: true, italic: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 3, [new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 1, 1, ["bold"], reference)
expected = new Delta(3, 3, [new RetainOp(0, 1), new RetainOp(1, 2, {bold: null}), new RetainOp(2, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 3, [new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 1, 1, ["bold", "italic"], reference)
expected = new Delta(3, 3, [new RetainOp(0, 1), new RetainOp(1, 2, {bold: null, italic: true}), new RetainOp(2, 3)])
assert(delta.isEqual(expected, "Expected #{expected} but got #{delta}"))

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 3, [new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 3, ["bold"], reference)
expected = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 3, 3, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3, {bold: null})])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 3, 3, ["bold", "italic"], reference)
expected = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3, {bold: null, italic: true})])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 3, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("abc"), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")
