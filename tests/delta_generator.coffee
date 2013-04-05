assert = require('chai').assert

Tandem = require('../index')
Delta      = Tandem.Delta
InsertOp   = Tandem.InsertOp
RetainOp   = Tandem.RetainOp
DeltaGen   = Tandem.DeltaGen

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 3, 1)
assert(delta.isEqual(new Delta(0, 5, [new RetainOp(0, 3), new RetainOp(4, 6)])))

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 3, 2)
assert(delta.isEqual(new Delta(0, 4, [new RetainOp(0, 3), new RetainOp(5, 6)])))

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 5, 1)
assert(delta.isEqual(new Delta(0, 5, [new RetainOp(0, 5)])))

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 5, 2)
assert(delta.isEqual(new Delta(0, 5, [new RetainOp(0, 5)])))

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 0, 1)
assert(delta.isEqual(new Delta(0, 5, [new RetainOp(1, 6)])))

delta = new Delta(0, 6, [new RetainOp(0, 6)])
DeltaGen.deleteAt(delta, 0, 6)
assert(delta.isEqual(new Delta(0, 0, [])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 0, 1)
assert(delta.isEqual(new Delta(0, 5, [new InsertOp("12345")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 0, 4)
assert(delta.isEqual(new Delta(0, 2, [new InsertOp("45")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 3, 1)
assert(delta.isEqual(new Delta(0, 5, [new InsertOp("01245")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 3, 3)
assert(delta.isEqual(new Delta(0, 3, [new InsertOp("012")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 3, 1)
assert(delta.isEqual(new Delta(0, 5, [new InsertOp("01245")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.deleteAt(delta, 5, 1)
assert(delta.isEqual(new Delta(0, 5, [new InsertOp("01234")])))

delta = new Delta(0, 6, [new RetainOp(0, 3), new InsertOp("abc")])
DeltaGen.deleteAt(delta, 2, 3)
assert(delta.isEqual(new Delta(0, 3, [new RetainOp(0, 2), new InsertOp("c")])))

delta = new Delta(0, 6, [new RetainOp(0, 3), new RetainOp(6, 9)])
DeltaGen.deleteAt(delta, 2, 3)
assert(delta.isEqual(new Delta(0, 3, [new RetainOp(0, 2), new RetainOp(8, 9)])))

delta = new Delta(0, 6, [new RetainOp(0, 3), new RetainOp(6, 9)])
DeltaGen.deleteAt(delta, 0, 3)
assert(delta.isEqual(new Delta(0, 3, [new RetainOp(6, 9)])))

delta = new Delta(0, 6, [new InsertOp("abc"), new InsertOp("efg")])
DeltaGen.deleteAt(delta, 2, 3)
assert(delta.isEqual(new Delta(0, 3, [new InsertOp("ab"), new InsertOp("g")])))

delta = new Delta(0, 6, [new InsertOp("abc"), new RetainOp(3, 6)])
DeltaGen.deleteAt(delta, 2, 3)
assert(delta.isEqual(new Delta(0, 3, [new InsertOp("ab"), new RetainOp(5, 6)])))

delta = new Delta(37, 28, [new RetainOp(0, 21), new RetainOp(24, 26), new RetainOp(32, 37)])
DeltaGen.deleteAt(delta, 12, 14)
assert(delta.isEqual(new Delta(37, 14, [new RetainOp(0, 12), new RetainOp(35, 37)])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.insertAt(delta, 3, "abcdefg")
assert(delta.isEqual(new Delta(0, 13, [new InsertOp("012abcdefg345")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.insertAt(delta, 0, "abcdefg")
assert(delta.isEqual(new Delta(0, 13, [new InsertOp("abcdefg012345")])))

delta = new Delta(0, 6, [new InsertOp("012345")])
DeltaGen.insertAt(delta, 6, "abcdefg")
assert(delta.isEqual(new Delta(0, 13, [new InsertOp("012345abcdefg")])))

reference = new Delta(0, 6, [new InsertOp("abc", {italic: true}),
                             new InsertOp("def", {})])
delta = new Delta(6, 6, [new RetainOp(0, 6)])
DeltaGen.formatAt(delta, 0, 5, ["italic"], reference)
expected = new Delta(6, 6, [new RetainOp(0, 3, {italic: null}),
                            new RetainOp(3, 6)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 6, [new InsertOp("abc", {italic: true}),
                             new InsertOp("def", {})])
delta = new Delta(6, 6, [new RetainOp(0, 6)])
DeltaGen.formatAt(delta, 1, 3, ["italic"], reference)
expected = new Delta(6, 6, [new RetainOp(0, 1),
                            new RetainOp(1, 3, {italic: null}),
                            new RetainOp(3, 6)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 1, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("a"), new InsertOp("bc", {bold: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 1, ["bold", "italic"], reference)
expected = new Delta(3, 6, [new InsertOp("a", {italic: true}), new InsertOp("bc", {bold: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 2, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("ab"), new InsertOp("c", {bold: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 0, 2, ["bold", "italic"], reference)
expected = new Delta(3, 6, [new InsertOp("ab", {italic: true}), new InsertOp("c", {bold: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 1, 2, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("a", {bold: true}), new InsertOp("bc"), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 1, 2, ["bold", "italic"], reference)
expected = new Delta(3, 6, [new InsertOp("a", {bold: true}), new InsertOp("bc", {italic: true}), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

reference = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
delta = new Delta(3, 6, [new InsertOp("abc", {bold: true}), new RetainOp(0, 3)])
DeltaGen.formatAt(delta, 2, 1, ["bold"], reference)
expected = new Delta(3, 6, [new InsertOp("ab", {bold: true}), new InsertOp("c"), new RetainOp(0, 3)])
assert(delta.isEqual(expected), "Expected #{expected} but got #{delta}")

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
