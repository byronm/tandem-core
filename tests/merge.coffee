expect = require('chai').expect

Tandem    = require('../index')
Delta     = Tandem.Delta
InsertOp  = Tandem.InsertOp
RetainOp  = Tandem.RetainOp

describe('delta', ->
  describe('merge', ->
    delta = new Delta(0, [
      new InsertOp("Hello", {authorId: 'Timon'})
      new InsertOp("World", {authorId: 'Pumba'})
    ])

    it('simple merge', ->
      leftDelta = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
      ])
      rightDelta = new Delta(0, [
        new InsertOp("World", {authorId: 'Pumba'})
      ])
      merger = leftDelta.merge(rightDelta)
      expect(merger).to.deep.equal(delta)
    )

    it('merge with compact', ->
      leftDelta = new Delta(0, [
        new InsertOp("Hello", {authorId: 'Timon'})
        new InsertOp("W", {authorId: 'Pumba'})
      ])
      rightDelta = new Delta(0, [
        new InsertOp("orld", {authorId: 'Pumba'})
      ])
      merger = leftDelta.merge(rightDelta)
      expect(merger).to.deep.equal(delta)
    )
  )
)
