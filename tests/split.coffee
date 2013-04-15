expect = require('chai').expect

Tandem    = require('../index')
Delta     = Tandem.Delta
InsertOp  = Tandem.InsertOp
RetainOp  = Tandem.RetainOp

describe('delta', ->
  describe('split', ->
    delta = new Delta(0, [
      new InsertOp("Hello", {authorId: 'Timon'})
      new InsertOp("World", {authorId: 'Pumba'})
    ])

    it('split without op splitting', ->
      expectedLeft = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
      ])
      expectedRight = new Delta(0, [
        new InsertOp("World", {authorId: 'Pumba'})
      ])
      [leftDelta, rightDelta] = delta.split(5)
      expect(leftDelta).to.deep.equal(expectedLeft)
      expect(rightDelta).to.deep.equal(expectedRight)
    )

    it('split with op splitting 1', ->
      expectedLeft = new Delta(0, [
        new InsertOp("Hell", {authorId: 'Timon'})
      ])
      expectedRight = new Delta(0, [
        new InsertOp("o", {authorId: 'Timon'})
        new InsertOp("World", {authorId: 'Pumba'})
      ])
      [leftDelta, rightDelta] = delta.split(4)
      expect(leftDelta).to.deep.equal(expectedLeft)
      expect(rightDelta).to.deep.equal(expectedRight)
    )

    it('split with op splitting 2', ->
      expectedLeft = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
        new InsertOp("W", {authorId: 'Pumba'})
      ])
      expectedRight = new Delta(0, [
        new InsertOp("orld", {authorId: 'Pumba'})
      ])
      [leftDelta, rightDelta] = delta.split(6)
      expect(leftDelta).to.deep.equal(expectedLeft)
      expect(rightDelta).to.deep.equal(expectedRight)
    )

    it('split at 0', ->
      expectedLeft = new Delta(0, [])
      expectedRight = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
        new InsertOp("World", {authorId: 'Pumba'})
      ])
      [leftDelta, rightDelta] = delta.split(0)
      expect(leftDelta).to.deep.equal(expectedLeft)
      expect(rightDelta).to.deep.equal(expectedRight)
    )

    it('split at boundary', ->
      expectedLeft = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
        new InsertOp("World", {authorId: 'Pumba'})
      ])
      expectedRight = new Delta(0, [])
      [leftDelta, rightDelta] = delta.split(10)
      expect(leftDelta).to.deep.equal(expectedLeft)
      expect(rightDelta).to.deep.equal(expectedRight)
    )
  )
)
