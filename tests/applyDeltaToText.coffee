assert = require('chai').assert

Tandem = require('../index')
Delta      = Tandem.Delta
InsertOp   = Tandem.InsertOp
RetainOp   = Tandem.RetainOp

testApplyDeltaToText = (delta, text, expected) ->
  computed = delta.applyToText(text)
  error = "Incorrect application. Got: " + computed + ", expected: " + expected
  assert.equal(computed, expected, error)

describe('applyDeltaToText', ->
  it('should append a character', ->
    text = "cat"
    delta = new Delta(3, 4, [new RetainOp(0, 3), new InsertOp("s")], 1)
    expected = "cats"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should prepend a character', ->
    text = "cat"
    delta = new Delta(3, 4, [new InsertOp("a"), new RetainOp(0, 3)], 1)
    expected = "acat"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should insert a character into the middle of the document', ->
    text = "cat"
    delta = new Delta(3, 4, [new RetainOp(0, 2), new InsertOp("n"), new RetainOp(2, 3)], 1)
    expected = "cant"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should prepend and append characters', ->
    text = "cat"
    delta = new Delta(3, 7, [new InsertOp("b"), new InsertOp("a"), new InsertOp("t"), new RetainOp(0, 3), new InsertOp("s")], 1)
    expected = "batcats"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should insert every other character', ->
    text = "cat"
    delta = new Delta(3, 6, [new RetainOp(0, 1), new InsertOp("h"), new RetainOp(1, 2), new InsertOp("n"), new RetainOp(2, 3), new InsertOp("s")], 1)
    expected = "chants"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should delete the last character', ->
    text = "cat"
    delta = new Delta(3, 2, [new RetainOp(0, 2)], 1)
    expected = "ca"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should delete the first character', ->
    text = "cat"
    delta = new Delta(3, 2, [new RetainOp(1, 3)], 1)
    expected = "at"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should delete the entire string', ->
    text = "cat"
    delta = new Delta(3, 0, [], 1)
    expected = ""
    testApplyDeltaToText(delta, text, expected)
  )

  it('should delete every other character', ->
    text = "hello"
    delta = new Delta(5, 2, [new RetainOp(1, 2), new RetainOp(3,4)], 1)
    expected = "el"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should insert to beginning, delete from end', ->
    text = "cat"
    delta = new Delta(3, 3, [new InsertOp("a"), new RetainOp(0, 2)], 1)
    expected = "aca"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should replace text with new text', ->
    text = "cat"
    delta = new Delta(3, 3, [new InsertOp("d"),
                             new InsertOp("o"),
                             new InsertOp("g")], 1)
    expected = "dog"
    testApplyDeltaToText(delta, text, expected)
  )

  it('should pass this fuzzer test we once failed', ->
    deltaA = new Delta(3, 17, [new InsertOp("evumzsdinkbgcp"),
                               new RetainOp(0, 3)])
    deltaB = new Delta(3, 33, [new InsertOp("rjieumfrlrukvmmeylxxwtc"),
                               new RetainOp(1, 2),
                               new InsertOp("mklxowze"),
                               new RetainOp(2, 3)])
    deltaBPrime = deltaB.transform(deltaA, true)
    deltaAPrime = deltaA.transform(deltaB, false)
    deltaAFinal = deltaA.compose(deltaBPrime)
    deltaBFinal = deltaB.compose(deltaAPrime)
    xA = deltaAFinal.applyToText("abc")
    xB = deltaBFinal.applyToText("abc")
    if (xA != xB)
      console.info "DeltaA:", deltaA
      console.info "DeltaB:", deltaB
      console.info "deltaAPrime:", deltaAPrime
      console.info "deltaBPrime:", deltaBPrime
      console.info "deltaAFinal:", deltaAFinal
      console.info "deltaBFinal:", deltaBFinal
      assert(false, "Documents diverged. xA is: " + xA + "xB is: " + xB)
    x = xA
  )
)
