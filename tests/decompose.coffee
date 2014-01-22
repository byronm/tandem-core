_        = require('lodash')
assert   = require('chai').assert
Tandem   = require('../index')
Delta    = Tandem.Delta
InsertOp = Tandem.InsertOp
RetainOp = Tandem.RetainOp

testDecompose = (deltaA, deltaC, expectedDecomposed) ->
  return unless _.all(deltaA.ops, ((op) -> return op.value?))
  return unless _.all(deltaC.ops, ((op) -> return op.value?))
  decomposed = deltaC.decompose(deltaA)
  decomposeError = """Incorrect decomposition. Got: #{decomposed.toString()},
                    expected: #{expectedDecomposed.toString()}"""
  assert(expectedDecomposed.isEqual(decomposed), decomposeError)

describe('decompose', ->
  # Basic edit tests
  it('should append', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 6, [new InsertOp("abcdef")])
    expectedDecomposed = new Delta(3, 6, [new RetainOp(0, 3),
                                          new InsertOp("def")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should prepend', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 6, [new InsertOp("defabc")])
    expectedDecomposed = new Delta(3, 6, [new InsertOp("def"),
                                          new RetainOp(0, 3)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should insert to the middle', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 6, [new InsertOp("abdefc")])
    expectedDecomposed = new Delta(3, 6, [new RetainOp(0, 2),
                                          new InsertOp("def"),
                                          new RetainOp(2, 3)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should yield alternating inserts', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 6, [new InsertOp("azbzcz")])
    expectedDecomposed = new Delta(3, 6, [new RetainOp(0, 1),
                                          new InsertOp("z"),
                                          new RetainOp(1, 2),
                                          new InsertOp("z"),
                                          new RetainOp(2, 3),
                                          new InsertOp("z")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should replace the tail', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("abc123")])
    expectedDecomposed = new Delta(6, 6, [new RetainOp(0, 3),
                                          new InsertOp("123")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should delete the tail and prepend to the head', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("123abc")])
    expectedDecomposed = new Delta(6, 6, [new InsertOp("123"),
                                          new RetainOp(0, 3)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should delete the head and append to the tail', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("def123")])
    expectedDecomposed = new Delta(6, 6, [new RetainOp(3, 6),
                                          new InsertOp("123")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should replace the head', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("123def")])
    expectedDecomposed = new Delta(6, 6, [new InsertOp("123"),
                                          new RetainOp(3, 6)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should trim the first and last chars', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 4, [new InsertOp("bcde")])
    expectedDecomposed = new Delta(6, 4, [new RetainOp(1, 5)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should delete from the middle', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 4, [new InsertOp("adef")])
    expectedDecomposed = new Delta(6, 4, [new RetainOp(0, 1),
                                          new RetainOp(3, 6)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should replace all', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("123456")])
    expectedDecomposed = new Delta(6, 6, [new InsertOp("123456")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  # Empty string tests
  it('should append to the empty string', ->
    deltaA = new Delta(0, 0, [new InsertOp("")])
    deltaC = new Delta(0, 3, [new InsertOp("abc")])
    expectedDecomposed = new Delta(0, 3, [new InsertOp("abc")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should append to the empty string', ->
    deltaA = new Delta(0, 0, [])
    deltaC = new Delta(0, 3, [new InsertOp("abc")])
    expectedDecomposed = new Delta(0, 3, [new InsertOp("abc")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should append the empty string', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 0, [new InsertOp("")])
    expectedDecomposed = new Delta(3, 0, [])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should append the empty string', ->
    deltaA = new Delta(0, 3, [new InsertOp("abc")])
    deltaC = new Delta(0, 0, [])
    expectedDecomposed = new Delta(3, 0, [])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should append the empty string to the empty string', ->
    deltaA = new Delta(0, 0, [])
    deltaC = new Delta(0, 0, [])
    expectedDecomposed = new Delta(0, 0, [])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should append the empty string to the empty string', ->
    deltaA = new Delta(0, 0, [])
    deltaC = new Delta(0, 0, [new InsertOp("")])
    expectedDecomposed = new Delta(0, 0, [new InsertOp("")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  # Attribution tests
  it('should append adjacent attributes', ->
    deltaA = new Delta(0, 0, [])
    deltaC = new Delta(0, 6, [new InsertOp("ab"),
                              new InsertOp("cd", {bold: true}),
                              new InsertOp("ef", {italic: true})])
    expectedDecomposed = new Delta(0, 6, [new InsertOp("ab"),
                                          new InsertOp("cd", {bold: true}),
                                          new InsertOp("ef", {italic: true})])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should retain text with no attributes when no attribution changes have
   been made', ->
    deltaA = new Delta(0, 2, [new InsertOp("ab")])
    deltaC = new Delta(0, 6, [new InsertOp("ab"),
                              new InsertOp("cd", {bold: true}),
                              new InsertOp("ef", {italic: true})])
    expectedDecomposed = new Delta(2, 6, [new RetainOp(0, 2),
                                          new InsertOp("cd", {bold: true}),
                                          new InsertOp("ef", {italic: true})])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should retain text with attributes when attribution changes have been
   made', ->
    deltaA = new Delta(0, 6, [new InsertOp("abcdef")])
    deltaC = new Delta(0, 6, [new InsertOp("a", {bold: true}),
                              new InsertOp("b", {bold: true, italic: true}),
                              new InsertOp("cd", {underline: true}),
                              new InsertOp("ef")])
    expectedDecomposed = new Delta(6, 6, [new RetainOp(0, 1, {bold: true}),
                                          new RetainOp(1, 2, {bold:true, italic: true}),
                                          new RetainOp(2, 4, {underline: true}),
                                          new RetainOp(4, 6)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  # Test that we favor retains over inserts
  it('should retain the middle', ->
    deltaA = new Delta(0, 6, [new InsertOp("abczde")])
    deltaC = new Delta(0, 6, [new InsertOp("zabcde")])
    expectedDecomposed = new Delta(6, 6, [new InsertOp("z"),
                                          new RetainOp(0, 3),
                                          new RetainOp(4, 6)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should retain the middle', ->
    deltaA = new Delta(0, 5, [new InsertOp("abcde")])
    deltaC = new Delta(0, 5, [new InsertOp("zbcd1")])
    expectedDecomposed = new Delta(5, 5, [new InsertOp("z"),
                                          new RetainOp(1, 4),
                                          new InsertOp("1")])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should retain the tail', ->
    deltaA = new Delta(0, 8, [new InsertOp("xbyabcde")])
    deltaC = new Delta(0, 6, [new InsertOp("zabcde")])
    expectedDecomposed = new Delta(8, 6, [new InsertOp("z"),
                                          new RetainOp(3, 8)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )

  it('should yield the minimal decomposition', ->
    deltaA = new Delta(0, 3, [new InsertOp("ab", {bold: true}),
                              new InsertOp("c")])
    deltaC = new Delta(0, 4, [new InsertOp("a", {bold: true}),
                              new InsertOp("c"),
                              new InsertOp("b", {bold: true})
                              new InsertOp("c")])

    expectedDecomposed = new Delta(3, 4, [new RetainOp(0, 1),
                                          new InsertOp("c"),
                                          new RetainOp(1, 3)])
    testDecompose(deltaA, deltaC, expectedDecomposed)
  )
)
