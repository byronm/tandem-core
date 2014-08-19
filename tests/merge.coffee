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

    it('with compact', ->
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

    it('with retains', ->
      newDelta = new Delta(0, [
        new InsertOp("This is a big |sentence")
      ])
      oldDelta = new Delta(0, [
        new InsertOp("This is a |sentence")
      ])
      decompose = newDelta.decompose(oldDelta)
      [newLeft, newRight] = newDelta.split(14)
      [oldLeft, oldRight] = oldDelta.split(10)
      expect(oldRight).to.deep.equal(newRight)
      leftDecompose = newLeft.decompose(oldLeft)
      rightDecompose = newRight.decompose(oldRight)
      merger = leftDecompose.merge(rightDecompose)
      expect(merger).to.deep.equal(decompose)
    )
  )
)
