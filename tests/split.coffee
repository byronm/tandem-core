# Copyright (c) 2012, Salesforce.com, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.  Redistributions in binary
# form must reproduce the above copyright notice, this list of conditions and
# the following disclaimer in the documentation and/or other materials provided
# with the distribution.  Neither the name of Salesforce.com nor the names of
# its contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.

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
