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

describe('compose', ->
  describe('attributes', ->
    it('should compose a text append by another author', ->
      deltaA = new Delta(0, 1, [
        new InsertOp("a", {authorId: 'Timon'})
      ])
      deltaB = new Delta(1, 2, [
        new RetainOp(0, 1, {authorId: 'Timon'})
        new InsertOp("b", {authorId: 'Pumba'})
      ])
      composed = deltaA.compose(deltaB)
      expected = new Delta(0, 2, [
        new InsertOp("a", {authorId: 'Timon'})
        new InsertOp("b", {authorId: 'Pumba'})
      ])
      expect(composed).to.deep.equal(expected)
    )

    it('should compose a text replacement by another author', ->
      deltaA = new Delta(0, 1, [
        new InsertOp("a", {authorId: 'Timon'})
      ])
      deltaB = new Delta(1, 2, [
        new InsertOp("Ab", {authorId: 'Pumba'})
      ])
      composed = deltaA.compose(deltaB)
      expected = new Delta(0, 2, [
        new InsertOp("Ab", {authorId: 'Pumba'})
      ])
      expect(composed).to.deep.equal(expected)
    )

    it('should compose a same text replacement by another author', ->
      deltaA = new Delta(0, 1, [
        new InsertOp("a", {authorId: 'Timon'})
      ])
      deltaB = new Delta(1, 2, [
        new RetainOp(0, 1, {authorId: 'Pumba'})
        new InsertOp("b", {authorId: 'Pumba'})
      ])
      composed = deltaA.compose(deltaB)
      expected = new Delta(0, 2, [
        new InsertOp("ab", {authorId: 'Pumba'})
      ])
      expect(composed).to.deep.equal(expected)
    )
  )
)
