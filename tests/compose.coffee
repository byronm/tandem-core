assert = require('chai').assert

Tandem = require('../index')
Delta      = Tandem.Delta
InsertOp   = Tandem.InsertOp
RetainOp   = Tandem.RetainOp

# Note: Though this file is dedicated to testing compose, we test decompose here
# as well since it's trivial to do so.
testComposeAndDecompose = (deltaA, deltaB, expectedComposed, expectedDecomposed) ->
  composed = deltaA.compose(deltaB)
  composeError =  "Incorrect composition. Got: #{composed.toString()},
    expected: #{expectedComposed.toString()}"
  assert(composed.isEqual(expectedComposed), composeError)
  return unless _.all(deltaA.ops, ((op) -> return InsertOp.isInsert(op)))
  return unless _.all(composed.ops, ((op) -> return InsertOp.isInsert(op)))
  decomposed = composed.decompose(deltaA)
  decomposeError = """Incorrect decomposition. Got: #{decomposed.toString()},
                    expected: #{expectedDecomposed.toString()}"""
  assert(decomposed.isEqual(expectedDecomposed), decomposeError)

describe('compose', ->
  it('should append', ->
    deltaA = new Delta(0, 5, [new InsertOp("hello")])
    deltaB = new Delta(5, 11, [new RetainOp(0, 5), new InsertOp(" world")])
    expectedComposed = new Delta(0, 11, [new InsertOp("hello world")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should prepend', ->
    deltaA = new Delta(0, 1, [new InsertOp("a")])
    deltaB = new Delta(1, 3, [new InsertOp("bb"), new RetainOp(0, 1)])
    expectedComposed = new Delta(0, 3, [new InsertOp("bba")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should insert to the middle', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 6, [new RetainOp(0, 1),
                              new InsertOp("123"),
                              new RetainOp(1, 3)])
    expectedComposed = new Delta(0, 6, [new InsertOp("a123bc")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should insert newlines', ->
    deltaA = new Delta(0, 7, [new InsertOp("abc\ndef")])
    deltaB = new Delta(7, 8, [new RetainOp(0, 1),
                              new InsertOp("\n"),
                              new RetainOp(1, 7)])
    expectedComposed = new Delta(0, 8, [new InsertOp("a\nbc\ndef")])
    expectedDecomposed = new Delta(7, 8, [new RetainOp(0, 1),
                                          new InsertOp("\n"),
                                          new RetainOp(1, 7)])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle newlines following an attribution and ending the doc', ->
    deltaA = new Delta(0, 4, [new InsertOp("ab"),
                              new InsertOp("c", {bold: true}),
                              new InsertOp("\n")])
    deltaC = new Delta(0, 3, [new InsertOp("ab\n")])
    decomposed = deltaC.decompose(deltaA)
    composed = deltaA.compose(decomposed)
    assert(deltaC.isEqual(composed))
  )

  it('should handle newlines following an attribution and not ending the doc', ->
    deltaA = new Delta(0, 7, [new InsertOp("ab"),
                              new InsertOp("c", {bold: true}),
                              new InsertOp("\ndef")])
    deltaC = new Delta(0, 6, [new InsertOp("ab\ndef")])
    decomposed = deltaC.decompose(deltaA)
    composed = deltaA.compose(decomposed)
    assert(deltaC.isEqual(composed))
  )

  it('should insert a character that appears later in the original document', ->
    deltaA = new Delta(0, 5, [new InsertOp("abczd")])
    deltaB = new Delta(5, 6, [new RetainOp(0, 1),
                              new InsertOp("z"),
                              new RetainOp(1, 5)])
    expectedComposed = new Delta(0, 6, [new InsertOp("azbczd")])
    expectedDecomposed = new Delta(5, 6, [new RetainOp(0, 1),
                                          new InsertOp("z"),
                                          new RetainOp(1, 5)])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should pass a specific fuzzer test we once failed', ->
    deltaA = new Delta(43, 43, [new RetainOp(0, 43)])
    deltaB = new Delta(43, 77, [
      new RetainOp(0, 2), new InsertOp("fbnuethzmh"),
      new RetainOp(2, 23), new InsertOp("vaufgrwnowolht"), new RetainOp(23, 31),
      new InsertOp("j"), new RetainOp(31, 37),
      new InsertOp("bagcfe"), new RetainOp(37, 40),
      new InsertOp("koo"), new RetainOp(40, 43)
    ])
    expectedComposed = new Delta(43, 77, [
      new RetainOp(0, 2), new InsertOp("fbnuethzmh"), new
      RetainOp(2, 23), new InsertOp("vaufgrwnowolht"), new RetainOp(23, 31),
      new InsertOp("j"), new RetainOp(31, 37), new
      InsertOp("bagcfe"), new RetainOp(37, 40), new
      InsertOp("koo"), new RetainOp(40, 43)
    ])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should pass a specific fuzzer test we once failed', ->
    deltaA = new Delta(43, 43, [new RetainOp(0, 43)])
    deltaB = new Delta(43, 77, [
      new RetainOp(0, 2), new InsertOp("fbnuethzmh"),
      new RetainOp(2, 23), new InsertOp("vaufgrwnowolht"), new RetainOp(23, 31),
      new InsertOp("j"), new RetainOp(31, 37),
      new InsertOp("bagcfe"), new RetainOp(37, 40),
      new InsertOp("koo"), new RetainOp(40, 43)
    ])
    composed = deltaA.compose(deltaB)
    expectedComposed = new Delta(43, 77, [
      new RetainOp(0, 2), new InsertOp("fbnuethzmh"), new
      RetainOp(2, 23), new InsertOp("vaufgrwnowolht"), new RetainOp(23, 31),
      new InsertOp("j"), new RetainOp(31, 37), new
      InsertOp("bagcfe"), new RetainOp(37, 40), new
      InsertOp("koo"), new RetainOp(40, 43)
    ])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the entire document', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 0, [])
    expectedComposed = new Delta(0, 0, [])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the final char', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 2, [new RetainOp(0, 2)])
    expectedComposed = new Delta(0, 2, [new InsertOp("ab")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the tail', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 1, [new RetainOp(0, 1)])
    expectedComposed = new Delta(0, 1, [new InsertOp("a")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the first char', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 2, [new RetainOp(1, 3)])
    expectedComposed = new Delta(0, 2, [new InsertOp("bc")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the middle characters', ->
    deltaA = new Delta(0, 4, [new InsertOp("abcd")])
    deltaB = new Delta(4, 2, [new RetainOp(0, 1), new RetainOp(3, 4)])
    expectedComposed = new Delta(0, 2, [new InsertOp("ad")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should append when there is a retain', ->
    deltaA = new Delta(3, 5, [new InsertOp("dd"), new RetainOp(0, 3)])
    deltaB = new Delta(5, 7, [new RetainOp(0, 5), new InsertOp("ee")])
    expectedComposed = new Delta(3, 7, [new InsertOp("dd"),
                                        new RetainOp(0, 3),
                                        new InsertOp("ee")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should prepend a character when the trailing string is a multichar match', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 4, [new InsertOp("d"), new RetainOp(0, 3)])
    expectedComposed = new Delta(0, 4, [new InsertOp("dabc")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should appending a character when preceding string is multichar match', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 4, [new RetainOp(0, 3), new InsertOp("d")])
    expectedComposed = new Delta(0, 4, [new InsertOp("abcd")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle when when deltaA has a retain', ->
    deltaA = new Delta(3, 6, [new RetainOp(0, 3), new InsertOp("abc")])
    deltaB = new Delta(6, 8, [new RetainOp(0, 6), new InsertOp("de")])
    expectedComposed = new Delta(3, 8, [new RetainOp(0, 3), new InsertOp("abcde")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle when deltaA has non-contiguous retains', ->
    deltaA = new Delta(6, 12, [new RetainOp(0, 3),
                               new InsertOp("abc"), new RetainOp(3, 6),
                               new InsertOp("def")])
    deltaB = new Delta(12, 18, [new InsertOp("123"),
      new RetainOp(0, 3), new InsertOp("456"), new RetainOp(3, 12)])
    expectedComposed = new Delta(6, 18, [new InsertOp("123"),
                                         new RetainOp(0, 3),
                                         new InsertOp("456abc"),
                                         new RetainOp(3, 6),
                                         new InsertOp("def")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle an insertion, followed by a retain, followed by a deletion', ->
    deltaA = new Delta(0, 4, [new InsertOp("abcd")])
    deltaB = new Delta(4, 4, [new InsertOp("d"), new RetainOp(0, 3)])
    expectedComposed = new Delta(0, 4, [new InsertOp("dabc")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle a retain followed by an insert', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 6, [new RetainOp(1, 3), new InsertOp("defg")])
    expectedComposed = new Delta(0, 6, [new InsertOp("bcdefg")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should replace existing text with the same text', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 2, [new InsertOp("bc")])
    expectedComposed = new Delta(0, 2, [new InsertOp("bc")])
    expectedDecomposed = new Delta(3, 2, [new RetainOp(1, 3)])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete retained text', ->
    deltaA = new Delta(0, 4, [new RetainOp(0, 4)])
    deltaB = new Delta(4, 0, [])
    expectedComposed = new Delta(0, 0, [])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  # Attribution tests
  it('should apply bold to inserted text', ->
    deltaA = new Delta(0, 3, [new InsertOp("cat")])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedComposed = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should keep attribution on inserted text after a retain', ->
    deltaA = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3)])
    expectedComposed = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should not remove an attribute if it is retained with undefined', ->
    deltaA = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: undefined})])
    expectedComposed = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    expectedDecomposed = new Delta(3, 3, [new RetainOp(0, 3, {})])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should apply bold to retained text', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should keep attribution on retained text after a retain', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3)])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should not remove an attribute if it is retained with undefined', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: undefined})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedDecomposed = new Delta(3, 3, [new RetainOp(0, 3, {})])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should remove attribution on inserted text if it is retained with null', ->
    deltaA = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(0, 3, [new InsertOp("cat")])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should remove attribution on retained text if it is retained with null', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should take the final value when the same attribute is retained multiple times', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 3})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 5})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 5})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should overwrite an attribute\'s value when inserted text is retained
   with a different value for the same attribute', ->
    deltaA = new Delta(3, 3, [new InsertOp("abc", {fontsize: 3})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 5})])
    expectedComposed = new Delta(3, 3, [new InsertOp("abc", {fontsize: 5})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should support multiple attributes on the same set of characters', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {italic: true})])
    expectedComposed = new Delta(3, 3,
      [new RetainOp(0, 3, {bold: true, italic: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )


  it('should support multiple attributes on the same set of characters', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3,
      [new RetainOp(0, 3, {italic: true, underline: true})])
    expectedComposed = new Delta(3, 3,
      [new RetainOp(0, 3, {bold: true, italic: true, underline: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should support adding and removing attributes from the same inserted
   characters in the same delta', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {italic: true, underline: true, bold: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {italic: true, underline: true, bold: null})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should support adding and removing attributes from the same retained characters in the same delta', ->
    deltaA = new Delta(3, 3, [new InsertOp("abc", {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {italic: true, underline: true, bold: null})])
    expectedComposed = new Delta(3, 3, [new InsertOp("abc", {italic: true, underline: true})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should persist null attribute if nothing to remove', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedDecomposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should delete the head with attribution', ->
    deltaA = new Delta(0, 11, [new InsertOp("bold", {bold: true}), new InsertOp("italics", {italic: true})])
    deltaC = new Delta(0, 7, [new InsertOp("italics", {italic: true})])
    decomposed = deltaC.decompose(deltaA)
    composed = deltaA.compose(decomposed)
    assert(composed.isEqual(deltaC))
  )

  # Nested composition tests, i.e., compose(a, compose(b, c))
  it('should handle nested compositions', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedDecomposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    testComposeAndDecompose(deltaA, deltaB.compose(deltaC), expectedComposed, expectedDecomposed)
  )

  it('should handle nested compositions', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    deltaD = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    assert(expectedComposed.isEqual(deltaA.compose(deltaB.compose(deltaC.compose(deltaD)))))
    assert(expectedComposed.isEqual(deltaA.compose(deltaB.compose(deltaC)).compose(deltaD)))
    assert(expectedComposed.isEqual((deltaA.compose(deltaB)).compose(deltaC.compose(deltaD))))
  )

  it('should handle nested compositions', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaD = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    assert(expectedComposed.isEqual(deltaA.compose(deltaB.compose(deltaC.compose(deltaD)))))
  )

  it('should handle nested compositions', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    deltaD = new Delta(3, 3, [new RetainOp(0, 3, {bold: true})])
    deltaE = new Delta(3, 3, [new RetainOp(0, 3, {bold: null})])
    expectedComposed = new Delta(0, 3, [new InsertOp("abc")])
    assert(expectedComposed.isEqual((deltaA.compose(deltaB.compose(deltaC.compose(deltaD)))).compose(deltaE)))
  )

  it('should handle nested compositions', ->
    deltaA = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 3})])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 5})])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaD = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: null})])
    expectedComposed = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: null})])
    assert(expectedComposed.isEqual((deltaA.compose(deltaB.compose(deltaC.compose(deltaD))))))
  )

  it('should handle nested compositions', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaB = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 3})])
    deltaC = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: 5})])
    deltaD = new Delta(3, 3, [new RetainOp(0, 3)])
    deltaE = new Delta(3, 3, [new RetainOp(0, 3, {fontsize: null})])
    expectedComposed = new Delta(0, 3, [new InsertOp("abc")])
    assert(expectedComposed.isEqual(deltaA.compose(deltaB.compose(deltaC.compose(deltaD.compose(deltaE))))))
  )

  # Test decompose + author attribution
  # TODO: Move these into attribution test module?
  it('should attribute adjacent authors', ->
    deltaA = new Delta(0, 1, [
            new InsertOp("a", {authorId: 'Timon'})
          ])
    deltaB = new Delta(1, 2, [
               new RetainOp(0, 1)
               new InsertOp("b", {authorId: 'Pumba'})
          ])
    expectedComposed = new Delta(0, 2, [
                       new InsertOp("a", {authorId: 'Timon'})
                       new InsertOp("b", {authorId: 'Pumba'})
                  ])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should replace author attribute', ->
    deltaA = new Delta(0, 1, [
             new InsertOp("a", {authorId: 'Timon'})
          ])
    deltaB = new Delta(1, 2, [
              new InsertOp("Ab", {authorId: 'Pumba'})
          ])
    expectedComposed = new Delta(0, 2, [
             new InsertOp("Ab", {authorId: 'Pumba'})
          ])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should replace author attribute', ->
    deltaA = new Delta(0, 1, [
             new InsertOp("a", {authorId: 'Timon'})
    ])
    deltaB = new Delta(1, 2, [
               new RetainOp(0, 1, {authorId: 'Pumba'})
               new InsertOp("b", {authorId: 'Pumba'})
    ])
    expectedComposed = new Delta(0, 2, [
                       new InsertOp("ab", {authorId: 'Pumba'})
    ])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should handle adding attribution to the middle of the document', ->
    deltaA = new Delta(10, 10, [new RetainOp(0, 10)])
    deltaB = new Delta(10, 10, [new RetainOp(0,3), new RetainOp(3,6,{bold:true}), new RetainOp(6,10)])
    composed = deltaA.compose(deltaB)
    assert(deltaB.isEqual(composed))
  )

  ##############################
  # Test Recursive Attributes
  ##############################
  it('shoud propagate recursive attributes through a retain', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should overwrite recursive attribute through retain with new attr val', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {color: 'blue'}})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'blue'}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should add new attributes to recursive attributes', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {bold: true}})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red', bold: true}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should add and replace recursive attributes', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {color: 'blue', bold: true}})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'blue', bold: true}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should remove and add separate recursive attributes', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {color: null, bold: true}})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {bold: true}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should overwrite nonrecursive attr val with recursive attr val', ->
    deltaA = new Delta(0, 1, [new InsertOp("a", {outer: 'nonobject'})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {color: 'red', bold: true}})])
    expectedComposed = new Delta(0, 1, [new InsertOp("a", {outer: {color: 'red', bold: true}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should overwrite recursive attr val with nonrecursive attr val', ->
    deltaA = new Delta(1, 1, [new RetainOp(0, 1, {outer: {color: 'red', bold: true}})])
    deltaB = new Delta(1, 1, [new InsertOp("a", {outer: 'nonobject'})])
    expectedComposed = new Delta(1, 1, [new InsertOp("a", {outer: 'nonobject'})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should add attribute when all ops are retains', ->
    deltaA = new Delta(1, 1, [new RetainOp(0, 1)])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: 'val1'})])
    expectedComposed = deltaB
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should replace attribute when all ops are retains', ->
    deltaA = new Delta(1, 1, [new RetainOp(0, 1, {outer: 'val1'})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: 'val2'})])
    expectedComposed = deltaB
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('should merge attributes when all ops are retains', ->
    deltaA = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner: 'val1'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner2: 'val2'}})])
    expectedComposed = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner: 'val1', inner2: 'val2'}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )

  it('it should remove and add attrs when all ops are retains', ->
    deltaA = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner: 'val1'}})])
    deltaB = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner: null, inner2: 'val2'}})])
    expectedComposed = new Delta(1, 1, [new RetainOp(0, 1, {outer: {inner: null, inner2: 'val2'}})])
    expectedDecomposed = deltaB
    testComposeAndDecompose(deltaA, deltaB, expectedComposed, expectedDecomposed)
  )
)
