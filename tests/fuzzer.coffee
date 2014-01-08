_        = require('lodash')
assert   = require('chai').assert
Tandem   = require('../index')
Delta    = Tandem.Delta
InsertOp = Tandem.InsertOp
RetainOp = Tandem.RetainOp
DeltaGen = Tandem.DeltaGen.getUtils()

##############################
# Fuzzer to test compose, transform, and applyDeltaToText.
# This test simulates two clients each making 10000 deltas on the document.
# On each iteration, each client applies their own delta, and the others
# delta, to their document. After doing so, we assert that the document is in
# the same state.
# Deltas are randomly generated. Each delta has somewhere between 0 and 10
# changes, and each change has a 50/50 chance of being a delete or insert. If it
# is an insert, then there will be a random number between 0 and 20 random
# characters inserted at a random index. If it is a delete, a random index will
# be deleted.
##############################
describe('Fuzzers', ->
  ##############################
  # Fuzz lots of changes being made to the doc (compose, transform, applyDeltaToText
  # all get fuzzed here)
  ##############################
  it('should pass all standard fuzzing', ->
    # x represents the consistent state of the document with deltas applied.
    x = "cat"
    xDelta = new Delta(0, 3, [new InsertOp("cat", {bold: true})])
    pass = _.all([1..1000], (i) ->
      deltaA = DeltaGen.getRandomDelta(xDelta)
      deltaB = DeltaGen.getRandomDelta(xDelta)
      # 50/50 as to which client gets priority
      isRemote = if Math.random() > 0.5 then true else false
      deltaBPrime = deltaB.transform(deltaA, isRemote)
      deltaAPrime = deltaA.transform(deltaB, !isRemote)
      deltaAFinal = deltaA.compose(deltaBPrime)
      deltaBFinal = deltaB.compose(deltaAPrime)
      xA = deltaAFinal.applyToText(x)
      xB = deltaBFinal.applyToText(x)
      # After each client applies their own change, and the other client's
      # transformed change (follow), the documents should be consistent
      x = xA
      xDelta = xDelta.compose(deltaAFinal)
      return xA == xB
    )
    assert(pass == true)
  )

  ##############################
  # Fuzz decompose
  ##############################
  it('should pass all decompose fuzzing', ->
    pass = _.all([1..1000], (i) ->
      numInsertions = _.random(1, 40)
      insertions = DeltaGen.getRandomString(numInsertions)
      deltaA = new Delta(0, insertions.length, [new InsertOp(insertions)])
      for j in [0...10]
        indexToFormat = _.random(0, deltaA.endLength - 1)
        numToFormat = _.random(0, deltaA.endLength - indexToFormat - 1)
        # Pick a random number of random attributes
        attributes = _.keys(DeltaGen.getDomain().booleanAttributes).concat(
          _.keys(DeltaGen.getDomain().nonBooleanAttributes))
        attributes = _.sortBy(attributes, -> return 0.5 - Math.random())
        numAttrs = Math.floor(Math.random() * (attributes.length + 1))
        attrs = attributes.slice(0, numAttrs)
        numToFormat = Math.floor(Math.random() * (deltaA.endLength - indexToFormat))
        DeltaGen.formatAt(deltaA, indexToFormat, numToFormat, attrs, new Delta(0, 0, []))

      deltaC = Delta.makeDelta(deltaA)
      numChanges = Math.floor(Math.random() * 11)
      for j in [0...numChanges]
        DeltaGen.addRandomOp(deltaC, deltaA)
      deltaC.compact()
      decomposed = deltaC.decompose(deltaA)
      composed = deltaA.compose(decomposed)
      return deltaC.isEqual(composed)
    )
    assert(pass == true)
  )
)
