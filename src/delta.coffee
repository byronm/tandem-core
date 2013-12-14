_                 = require('underscore')._
diff_match_patch  = require('./diff_match_patch')
Op                = require('./op')
InsertOp          = require('./insert')
RetainOp          = require('./retain')

dmp = new diff_match_patch()

class Delta
  @getIdentity: (length) ->
    return new Delta(length, length, [new RetainOp(0, length)])

  @getInitial: (contents) ->
    return new Delta(0, contents.length, [new InsertOp(contents)])

  @isDelta: (delta) ->
    if (delta? && typeof delta == "object" && typeof delta.startLength == "number" &&
        typeof delta.endLength == "number" && typeof delta.ops == "object")
      for op in delta.ops
        return false unless Delta.isRetain(op) or Delta.isInsert(op)
      return true
    return false

  @isInsert: (op) ->
    return InsertOp.isInsert(op)

  @isRetain: (op) ->
    return RetainOp.isRetain(op)

  @makeDelta: (obj) ->
    return new Delta(obj.startLength, obj.endLength, _.map(obj.ops, (op) ->
      if InsertOp.isInsert(op)
        return new InsertOp(op.value, op.attributes)
      else if RetainOp.isRetain(op)
        return new RetainOp(op.start, op.end, op.attributes)
      else
        return null
    ))

  @makeDeleteDelta: (startLength, index, length) ->
    ops = []
    ops.push(new RetainOp(0, index)) if 0 < index
    ops.push(new RetainOp(index + length, startLength)) if index + length < startLength
    return new Delta(startLength, ops)

  @makeInsertDelta: (startLength, index, value, attributes) ->
    ops = [new InsertOp(value, attributes)]
    ops.unshift(new RetainOp(0, index)) if 0 < index
    ops.push(new RetainOp(index, startLength)) if index < startLength
    return new Delta(startLength, ops)

  @makeRetainDelta: (startLength, index, length, attributes) ->
    ops = [new RetainOp(index, index + length, attributes)]
    ops.unshift(new RetainOp(0, index)) if 0 < index
    ops.push(new RetainOp(index + length, startLength)) if index + length < startLength
    return new Delta(startLength, ops)

  constructor: (@startLength, @endLength, @ops) ->
    unless @ops?
      @ops = @endLength
      @endLength = null
    @ops = _.map(@ops, (op) ->
      if RetainOp.isRetain(op)
        return op
      else if InsertOp.isInsert(op)
        return op
      else
        throw new Error("Creating delta with invalid op. Expecting an insert or retain.")
    )
    this.compact()
    length = _.reduce(@ops, (count, op) ->
      return count + op.getLength()
    , 0)
    if @endLength? and length != @endLength
      throw new Error("Expecting end length of #{length}")
    else
      @endLength = length

  # insertFn(index, text), deleteFn(index, length), applyAttrFn(index, length, attribute, value)
  apply: (insertFn = (->), deleteFn = (->), applyAttrFn = (->), context = null) ->
    return if this.isIdentity()
    index = 0       # Stores where the last retain end was, so if we see another one, we know to delete
    offset = 0      # Tracks how many characters inserted to correctly offset new text
    retains = []
    _.each(@ops, (op) =>
      if Delta.isInsert(op)
        insertFn.call(context, index + offset, op.value, op.attributes)
        offset += op.getLength()
      else if Delta.isRetain(op)
        if op.start > index
          deleteFn.call(context, index + offset, op.start - index)
          offset -= (op.start - index)
        retains.push(new RetainOp(op.start + offset, op.end + offset, op.attributes))
        index = op.end
    )
    # If end of text was deleted
    if @endLength < @startLength + offset
      deleteFn.call(context, @endLength, @startLength + offset - @endLength)
    _.each(retains, (op) =>
      # In case we have instruction that is replace attr1 with attr2 by att1 -> null -> attr2
      # we need to apply null first since otherwise attr1 -> attr2 -> null is not what we want
      _.each(op.attributes, (value, format) =>
        applyAttrFn.call(context, op.start, op.end - op.start, format, value) if value == null
      )
      _.each(op.attributes, (value, format) =>
        applyAttrFn.call(context, op.start, op.end - op.start, format, value) if value?
      )
    )

  applyToText: (text) ->
    delta = this
    if text.length != delta.startLength
      throw new Error("Start length of delta: #{delta.startLength} is not equal to the text: #{text.length}")
    appliedText = []
    for op in delta.ops
      if Delta.isInsert(op)
        appliedText.push(op.value)
      else
        appliedText.push(text.substring(op.start, op.end))
    result = appliedText.join("")
    if delta.endLength != result.length
      throw new Error("End length of delta: #{delta.endLength} is not equal to result text: #{result.length}")
    return result

  canCompose: (delta) ->
    return Delta.isDelta(delta) and @endLength == delta.startLength

  compact: ->
    compacted = []
    _.each(@ops, (op) ->
      return if op.getLength() == 0
      if compacted.length == 0
        compacted.push(op)
      else
        last = _.last(compacted)
        if InsertOp.isInsert(last) && InsertOp.isInsert(op) && last.attributesMatch(op)
          compacted[compacted.length - 1] = new InsertOp(last.value + op.value, op.attributes)
        else if RetainOp.isRetain(last) && RetainOp.isRetain(op) && last.end == op.start && last.attributesMatch(op)
          compacted[compacted.length - 1] = new RetainOp(last.start, op.end, op.attributes)
        else
          compacted.push(op)
    )
    @ops = compacted

  # Inserts in deltaB are given priority. Retains in deltaB are indexes into A,
  # and we take whatever is there (insert or retain).
  compose: (deltaB) ->
    throw new Error('Cannot compose delta') unless this.canCompose(deltaB)
    deltaA = this
    composed = []
    for opInB in deltaB.ops
      if Delta.isInsert(opInB)
        composed.push(opInB)
      else if Delta.isRetain(opInB)
        opsInRange = deltaA.getOpsAt(opInB.start, opInB.getLength())
        opsInRange = _.map(opsInRange, (opInA) ->
          if Delta.isInsert(opInA)
            return new InsertOp(opInA.value, opInA.composeAttributes(opInB.attributes))
          else
            return new RetainOp(opInA.start, opInA.end, opInA.composeAttributes(opInB.attributes))
        )
        composed = composed.concat(opsInRange)
      else
        throw new Error('Invalid op in deltaB when composing')
    return new Delta(deltaA.startLength, deltaB.endLength, composed)

  # For each element in deltaC, compare it to the current element in deltaA in
  # order to construct deltaB. Given A and C, there is more than one valid B.
  # Its impossible to guarantee that decompose yields the actual B that was
  # used in the original composition. However, the function is deterministic in
  # which of the possible B's it chooses. How it works:
  # 1. Inserts in deltaC are matched against the current elem in deltaA. If
  #    there is a match, we create a corresponding retain in deltaB. Otherwise,
  #    we create an insertion in deltaB.
  # 2. We disallow retains in either of deltaA or deltaC.
  decompose: (deltaA) ->
    deltaC = this
    throw new Error("Decompose called when deltaA is not a Delta, type: " + typeof deltaA) unless Delta.isDelta(deltaA)
    throw new Error("startLength #{deltaA.startLength} / startLength #{@startLength} mismatch") unless deltaA.startLength == @startLength
    throw new Error("DeltaA has retain in decompose") unless _.all(deltaA.ops, ((op) -> return Delta.isInsert(op)))
    throw new Error("DeltaC has retain in decompose") unless _.all(deltaC.ops, ((op) -> return Delta.isInsert(op)))

    decomposeAttributes = (attrA, attrC) ->
      decomposedAttributes = {}
      for key, value of attrC
        if attrA[key] == undefined or attrA[key] != value
          if attrA[key] != null and typeof attrA[key] == 'object' and value != null and typeof value == 'object'
            decomposedAttributes[key] = decomposeAttributes(attrA[key], value)
          else
            decomposedAttributes[key] = value
      for key, value of attrA
        if attrC[key] == undefined
          decomposedAttributes[key] = null
      return decomposedAttributes

    insertDelta = deltaA.diff(deltaC)
    ops = []
    offset = 0
    _.each(insertDelta.ops, (op) ->
      opsInC = deltaC.getOpsAt(offset, op.getLength())
      offsetC = 0
      _.each(opsInC, (opInC) ->
        if Delta.isInsert(op)
          d = new InsertOp(op.value.substring(offsetC, offsetC + opInC.getLength()), opInC.attributes)
          ops.push(d)
        else if Delta.isRetain(op)
          opsInA = deltaA.getOpsAt(op.start + offsetC, opInC.getLength())
          offsetA = 0
          _.each(opsInA, (opInA) ->
            attributes = decomposeAttributes(opInA.attributes, opInC.attributes)
            start = op.start + offsetA + offsetC
            e = new RetainOp(start, start + opInA.getLength(), attributes)
            ops.push(e)
            offsetA += opInA.getLength()
          )
        else
          throw new Error("Invalid delta in deltaB when composing")
        offsetC += opInC.getLength()
      )
      offset += op.getLength()
    )

    deltaB = new Delta(insertDelta.startLength, insertDelta.endLength, ops)
    return deltaB

  diff: (other) ->
    [textA, textC] = _.map([this, other], (delta) ->
      return _.map(delta.ops, (op) ->
        return if op.value? then op.value else ""
      ).join('')
    )
    unless textA == '' and textC == ''
      diff = dmp.diff_main(textA, textC)
      throw new Error("diffToDelta called with diff with length <= 0") if diff.length <= 0
      originalLength = 0
      finalLength = 0
      ops = []
      # For each difference apply them separately so we do not disrupt the cursor
      for [operation, value] in diff
        switch operation
          when diff_match_patch.DIFF_DELETE
            # Deletes implied
            originalLength += value.length
          when diff_match_patch.DIFF_INSERT
            ops.push(new InsertOp(value))
            finalLength += value.length
          when diff_match_patch.DIFF_EQUAL
            ops.push(new RetainOp(originalLength, originalLength + value.length))
            originalLength += value.length
            finalLength += value.length
      insertDelta = new Delta(originalLength, finalLength, ops)
    else
      insertDelta = new Delta(0, 0, [])
    return insertDelta

  # We compute the follow according to the following rules:
  # 1. Insertions in deltaA become retained characters in the follow set
  # 2. Insertions in deltaB become inserted characters in the follow set
  # 3. Characters retained in deltaA and deltaB become retained characters in
  #    the follow set
  follows: (deltaA, aIsRemote = false) ->
    deltaB = this
    errMsg = "Follows called when deltaA is not a Delta, type: "
    throw new Error(errMsg + typeof deltaA) unless Delta.isDelta(deltaA)

    deltaA = new Delta(deltaA.startLength, deltaA.endLength, deltaA.ops)
    deltaB = new Delta(deltaB.startLength, deltaB.endLength, deltaB.ops)
    followStartLength = deltaA.endLength
    followOps = []
    indexA = indexB = 0 # Tracks character offset in the 'document'
    elemIndexA = elemIndexB = 0 # Tracks offset into the ops list
    while elemIndexA < deltaA.ops.length and elemIndexB < deltaB.ops.length
      elemA = deltaA.ops[elemIndexA]
      elemB = deltaB.ops[elemIndexB]

      if Delta.isInsert(elemA) and Delta.isInsert(elemB)
        length = Math.min(elemA.getLength(), elemB.getLength())
        if aIsRemote
          followOps.push(new RetainOp(indexA, indexA + length))
          indexA += length
          if length == elemA.getLength()
            elemIndexA++
          else if length < elemA.getLength()
            deltaA.ops[elemIndexA] = _.last(elemA.split(length))
          else
            throw new Error("Invalid elem length in follows")
        else
          followOps.push(_.first(elemB.split(length)))
          indexB += length
          if length == elemB.getLength()
            elemIndexB++
          else
            deltaB.ops[elemIndexB] = _.last(elemB.split(length))

      else if Delta.isRetain(elemA) and Delta.isRetain(elemB)
        if elemA.end < elemB.start
          # Not a match, can't save. Throw away lower and adv.
          indexA += elemA.getLength()
          elemIndexA++
        else if elemB.end < elemA.start
          # Not a match, can't save. Throw away lower and adv.
          indexB += elemB.getLength()
          elemIndexB++
        else
          # A subrange or the entire range matches
          if elemA.start < elemB.start
            indexA += elemB.start - elemA.start
            elemA = deltaA.ops[elemIndexA] = new RetainOp(elemB.start,
              elemA.end, elemA.attributes)
          else if elemB.start < elemA.start
            indexB += elemA.start - elemB.start
            elemB = deltaB.ops[elemIndexB] = new RetainOp(elemA.start,
              elemB.end, elemB.attributes)
          errMsg = "RetainOps must have same start length in follow set"
          throw new Error(errMsg) if elemA.start != elemB.start
          length = Math.min(elemA.end, elemB.end) - elemA.start
          addedAttributes = elemA.addAttributes(elemB.attributes)
          # Keep the retain
          followOps.push(new RetainOp(indexA, indexA + length,
            addedAttributes))
          indexA += length
          indexB += length
          if (elemA.end == elemB.end)
            elemIndexA++
            elemIndexB++
          else if (elemA.end < elemB.end)
            elemIndexA++
            deltaB.ops[elemIndexB] = _.last(elemB.split(length))
          else
            deltaA.ops[elemIndexA] = _.last(elemA.split(length))
            elemIndexB++

      else if Delta.isInsert(elemA) and Delta.isRetain(elemB)
        followOps.push(new RetainOp(indexA, indexA + elemA.getLength()))
        indexA += elemA.getLength()
        elemIndexA++
      else if Delta.isRetain(elemA) and Delta.isInsert(elemB)
        followOps.push(elemB)
        indexB += elemB.getLength()
        elemIndexB++

    # Remaining loops account for different length ops, only inserts will be
    # accepted
    while elemIndexA < deltaA.ops.length
      elemA = deltaA.ops[elemIndexA]
      if Delta.isInsert(elemA) # retain elemA
        followOps.push(new RetainOp(indexA, indexA + elemA.getLength()))
      indexA += elemA.getLength()
      elemIndexA++

    while elemIndexB < deltaB.ops.length
      elemB = deltaB.ops[elemIndexB]
      followOps.push(elemB) if Delta.isInsert(elemB) # insert elemB
      indexB += elemB.getLength()
      elemIndexB++

    followEndLength = 0
    for elem in followOps
      followEndLength += elem.getLength()
    follow = new Delta(followStartLength, followEndLength, followOps)
    return follow

  getOpsAt: (index, length) ->
    changes = []
    if @savedOpOffset? and @savedOpOffset < index
      offset = @savedOpOffset
    else
      offset = @savedOpOffset = @savedOpIndex = 0
    for op in @ops.slice(@savedOpIndex)
      break if offset >= index + length
      opLength = op.getLength()
      if index < offset + opLength
        start = Math.max(index - offset, 0)
        getLength = Math.min(opLength - start, index + length - offset - start)
        changes.push(op.getAt(start, getLength))
      offset += opLength
      @savedOpIndex += 1
      @savedOpOffset += opLength
    return changes

  # Given A and B, returns B' s.t. ABB' yields A.
  invert: (deltaB) ->
    throw new Error("Invert called on invalid delta containing non-insert ops") unless this.isInsertsOnly()
    deltaA = this
    deltaC = deltaA.compose(deltaB)
    inverse = deltaA.decompose(deltaC)
    return inverse

  isEqual: (other) ->
    return false unless other
    return false if @startLength != other.startLength or @endLength != other.endLength
    return false if !_.isArray(other.ops) or @ops.length != other.ops.length
    return _.all(@ops, (op, i) ->
      op.isEqual(other.ops[i])
    )

  isIdentity: ->
    if @startLength == @endLength
      if @ops.length == 0
        return true
      index = 0
      for op in @ops
        if !RetainOp.isRetain(op) then return false
        if op.start != index then return false
        if !(op.numAttributes() == 0 || (op.numAttributes() == 1 && _.has(op.attributes, 'authorId')))
          return false
        index = op.end
      if index != @endLength then return false
      return true
    return false

  isInsertsOnly: ->
    return _.every(@ops, (op) ->
      return Delta.isInsert(op)
    )

  merge: (other) ->
    ops = _.map(other.ops, (op) =>
      if RetainOp.isRetain(op)
        return new RetainOp(op.start + @startLength, op.end + @startLength, op.attributes)
      else
        return op
    )
    ops = @ops.concat(ops)
    return new Delta(@startLength + other.startLength, ops)

  split: (index) ->
    throw new Error("Split only implemented for inserts only") unless this.isInsertsOnly()
    throw new Error("Split at invalid index") unless 0 <= index and index <= @endLength
    leftOps = []
    rightOps = []
    _.reduce(@ops, (offset, op) ->
      if offset + op.getLength() <= index
        leftOps.push(op)
      else if offset >= index
        rightOps.push(op)
      else
        [left, right] = op.split(index - offset)
        leftOps.push(left)
        rightOps.push(right)
      return offset + op.getLength()
    , 0)
    return [new Delta(0, leftOps), new Delta(0, rightOps)]

  toString: ->
    return "{(#{@startLength}->#{@endLength}) [#{@ops.join(', ')}]}"


module.exports = Delta
