expect = require('chai').expect
Tandem = require('../index')

describe('makeInsertDelta', ->
  startLength = 'Hello world'.length
  it('should make insert delta', ->
    index = 'Hello'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, index)
      new Tandem.InsertOp(' new', { bold: true })
      new Tandem.RetainOp(index, startLength)
    ])
    delta = Tandem.Delta.makeInsertDelta(startLength, index, ' new', { bold: true })
    expect(delta).to.deep.equal(expected)
  )

  it('should make insert delta at start', ->
    expected = new Tandem.Delta(startLength, [
      new Tandem.InsertOp('Well ', { bold: true })
      new Tandem.RetainOp(0, startLength)
    ])
    delta = Tandem.Delta.makeInsertDelta(startLength, 0, 'Well ', { bold: true })
    expect(delta).to.deep.equal(expected)
  )

  it('should make insert delta at end', ->
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, startLength)
      new Tandem.InsertOp('!', { bold: true })
    ])
    delta = Tandem.Delta.makeInsertDelta(startLength, startLength, '!', { bold: true })
    expect(delta).to.deep.equal(expected)
  )
)

describe('makeDeleteDelta', ->
  startLength = 'Well hello new world!'.length
  it('should make delete delta', ->
    index = 'Well hello'.length
    length = 'new '.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, index)
      new Tandem.RetainOp(index + length, startLength)
    ])
    delta = new Tandem.Delta.makeDeleteDelta(startLength, index, length)
    expect(delta).to.deep.equal(expected)
  )

  it('should make delete delta at start', ->
    length = 'Well'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(length, startLength)
    ])
    delta = new Tandem.Delta.makeDeleteDelta(startLength, 0, length)
    expect(delta).to.deep.equal(expected)
  )

  it('should make delete delta at end', ->
    length = '!'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, startLength - length)
    ])
    delta = new Tandem.Delta.makeDeleteDelta(startLength, startLength - length, length)
    expect(delta).to.deep.equal(expected)
  )
)

describe('makeRetainDelta', ->
  startLength = 'Hello new world!'.length
  it('should make retain delta', ->
    index = 'Hello '.length
    length = 'new'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, index)
      new Tandem.RetainOp(index, index + length, { bold: true })
      new Tandem.RetainOp(index + length, startLength)
    ])
    delta = new Tandem.Delta.makeRetainDelta(startLength, index, length, { bold: true })
    expect(delta).to.deep.equal(expected)
  )

  it('should make retain delta at start', ->
    length = 'Hello'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, length, { bold: true })
      new Tandem.RetainOp(length, startLength)
    ])
    delta = new Tandem.Delta.makeRetainDelta(startLength, 0, length, { bold: true })
    expect(delta).to.deep.equal(expected)
  )

  it('should make retain delta at end', ->
    index = 'Hello new '.length
    length = 'world!'.length
    expected = new Tandem.Delta(startLength, [
      new Tandem.RetainOp(0, index)
      new Tandem.RetainOp(index, index + length, { bold: true })
    ])
    delta = new Tandem.Delta.makeRetainDelta(startLength, index, length, { bold: true })
    expect(delta).to.deep.equal(expected)
  )
)
