diff_match_patch  = require('./diff_match_patch')
Op                = require('./op')
InsertOp          = require('./insert')
RetainOp          = require('./retain')


dmp = new diff_match_patch()


class Delta
  @copy: (subject) ->
    changes = []
    for op in subject.ops
      if Delta.isRetain(op)
        changes.push(RetainOp.copy(op))
      else
        changes.push(InsertOp.copy(op))
    return new Delta(subject.startLength, subject.endLength, changes)

  @getIdentity: (length) ->
    delta = new Delta(length, length, [new RetainOp(0, length)])
    return delta

  @getInitial: (contents) ->
    return new Delta(0, contents.length, [new InsertOp(contents)])

  @isDelta: (delta) ->
    if (delta? && typeof delta == "object" && typeof delta.startLength == "number" &&
        typeof delta.endLength == "number" && typeof delta.ops == "object")
      for op in delta.ops
        if !Delta.isRetain(op) && !Delta.isInsert(op)
          return false
      return true
    return false

  @isInsert: (op) ->
    return InsertOp.isInsert(op)

  @isRetain: (op) ->
    return RetainOp.isRetain(op)

  @makeDelta: (obj) ->
    return new Delta(obj.startLength, obj.endLength, obj.ops)

  constructor: (@startLength, @endLength, @ops) ->
    unless @ops?
      @ops = @endLength
      @endLength = null
    this.compact()
    length = _.reduce(@ops, (count, op) ->
      return count + op.getLength()
    , 0)
    if @endLength?
      console.assert(length == @endLength, "Expecting end length of", length, this)
    else
      @endLength = length

  # insertFn(index, text), deleteFn(index, length), applyAttrFn(index, length, attribute, value)
  apply: (insertFn, deleteFn, applyAttrFn, context = null) ->
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
      else
        console.warn('Unrecognized type in delta', op)
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
    console.assert(text.length == delta.startLength, "Start length of delta: " + delta.startLength + " is not equal to the text: " + text.length)
    appliedText = []
    for op in delta.ops
      if Delta.isInsert(op)
        appliedText.push(op.value)
      else
        appliedText.push(text.substring(op.start, op.end))
    result = appliedText.join("")
    if delta.endLength != result.length
      console.log "Delta", delta
      console.log "text", text
      console.log "result", result
      console.assert(false, "End length of delta: " + delta.endLength + " is not equal to result text: " + result.length )
    return result

  canCompose: (delta) ->
    return Delta.isDelta(delta) and @endLength == delta.startLength

  compact: ->
    this.normalize()
    compacted = []
    _.each(@ops, (op) ->
      if compacted.length == 0
        compacted.push(op) unless RetainOp.isRetain(op) && op.start == op.end
      else
        if RetainOp.isRetain(op) && op.start == op.end
          return
        last = _.last(compacted)
        if InsertOp.isInsert(last) && InsertOp.isInsert(op) && last.attributesMatch(op)
          # If two neighboring inserts, combine
          last.value = last.value + op.value
        else if RetainOp.isRetain(last) && RetainOp.isRetain(op) && last.end == op.start && last.attributesMatch(op)
          # If two neighboring ranges first's end + 1 == second's start, combine
          last.end = op.end
        else
          # Cannot coalesce with previous
          compacted.push(op)
    )
    @ops = compacted

  # Inserts in deltaB are given priority. Retains in deltaB are indexes into A,
  # and we take whatever is there (insert or retain).
  compose: (deltaB) ->
    console.assert(this.canCompose(deltaB), "Cannot compose delta", this, deltaB)
    deltaA = new Delta(@startLength, @endLength, @ops)
    deltaB = new Delta(deltaB.startLength, deltaB.endLength, deltaB.ops)

    composed = []
    for opInB in deltaB.ops
      if Delta.isInsert(opInB)
        composed.push(opInB)
      else if Delta.isRetain(opInB)
        opsInRange = deltaA.getOpsAt(opInB.start, opInB.end - opInB.start)
        opsInRange = _.map(opsInRange, (opInA) ->
          if Delta.isInsert(opInA)
            return new InsertOp(opInA.value, opInA.composeAttributes(opInB.attributes))
          else
            return new RetainOp(opInA.start, opInA.end, opInA.composeAttributes(opInB.attributes))
        )
        composed = composed.concat(opsInRange)
      else
        console.assert(false, "Invalid op in deltaB when composing", deltaB)

    deltaC = new Delta(deltaA.startLength, deltaB.endLength, composed)
    console.assert(Delta.isDelta(deltaC), "Composed returning invalid Delta", deltaC)
    return deltaC

  # For each element in deltaC, compare it to the current element in deltaA in
  # order to construct deltaB. Given A and C, there is more than one valid B.
  # Its impossible to guarantee that decompose yields the actual B that was
  # used in the original composition. However, the function is deterministic in
  # which of the possible B's it chooses. How it works:
  # 1. Inserts in deltaC are matched against the current elem in deltaA. If
  #    there is a match, we create a corresponding retain in deltaB. Otherwise,
  #    we create an insertion in deltaB.
  # 2. Retains in deltaC become retains in deltaB, which reference the original
  #    retain in deltaA.
  decompose: (deltaA) ->
    deltaC = this
    console.assert(Delta.isDelta(deltaA), "Decompose called when deltaA is not a Delta, type: " + typeof deltaA)
    console.assert(deltaA.startLength == @startLength, "startLength #{deltaA.startLength} / startLength #{@startLength} mismatch")
    console.assert(_.all(deltaA.ops, ((op) -> return Delta.isInsert(op))), "DeltaA has retain in decompose")
    console.assert(_.all(deltaC.ops, ((op) -> return Delta.isInsert(op))), "DeltaC has retain in decompose")

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
          console.error("Invalid delta in deltaB when composing", deltaB)
        offsetC += opInC.getLength()
      )
      offset += op.getLength()
    )

    deltaB = new Delta(insertDelta.startLength, insertDelta.endLength, ops)
    return deltaB

  diff: (other) ->
    diffToDelta = (diff) ->
      console.assert(diff.length > 0, "diffToDelta called with diff with length <= 0")
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
      return new Delta(originalLength, finalLength, ops)

    deltaToText = (delta) ->
      return _.map(delta.ops, (op) ->
        return if op.value? then op.value else ""
      ).join('')

    diffTexts = (oldText, newText) ->
      diff = dmp.diff_main(oldText, newText)
      return diff

    textA = deltaToText(this)
    textC = deltaToText(other)
    unless textA == '' and textC == ''
      diff = diffTexts(textA, textC)
      insertDelta = diffToDelta(diff)
    else
      insertDelta = new Delta(0, 0, [])
    return insertDelta

  # We compute the follow according to the following rules:
  # 1. Insertions in deltaA become retained characters in the follow set
  # 2. Insertions in deltaB become inserted characters in the follow set
  # 3. Characters retained in deltaA and deltaB become retained characters in
  #    the follow set
  follows: (deltaA, aIsRemote) ->
    deltaB = this
    console.assert(Delta.isDelta(deltaA), "Follows called when deltaA is not a Delta, type: " + typeof deltaA, deltaA)
    console.assert(aIsRemote?, "Remote delta not specified")

    deltaA = new Delta(deltaA.startLength, deltaA.endLength, deltaA.ops)
    deltaB = new Delta(deltaB.startLength, deltaB.endLength, deltaB.ops)
    followStartLength = deltaA.endLength
    followSet = []
    indexA = indexB = 0 # Tracks character offset in the 'document'
    elemIndexA = elemIndexB = 0 # Tracks offset into the ops list
    while elemIndexA < deltaA.ops.length and elemIndexB < deltaB.ops.length
      elemA = deltaA.ops[elemIndexA]
      elemB = deltaB.ops[elemIndexB]

      if Delta.isInsert(elemA) and Delta.isInsert(elemB)
        length = Math.min(elemA.getLength(), elemB.getLength())
        if aIsRemote
          followSet.push(new RetainOp(indexA, indexA + length))
          indexA += length
          if length == elemA.getLength()
            elemIndexA++
          else
            console.assert(length < elemA.getLength())
            deltaA.ops[elemIndexA] = _.last(elemA.split(length))
        else
          followSet.push(_.first(elemB.split(length)))
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
            elemA = deltaA.ops[elemIndexA] = new RetainOp(elemB.start, elemA.end, elemA.attributes)
          else if elemB.start < elemA.start
            indexB += elemA.start - elemB.start
            elemB = deltaB.ops[elemIndexB] = new RetainOp(elemA.start, elemB.end, elemB.attributes)

          console.assert(elemA.start == elemB.start, "RetainOps must have same
          start length when propagating into followset", elemA, elemB)
          length = Math.min(elemA.end, elemB.end) - elemA.start
          addedAttributes = elemA.addAttributes(elemB.attributes)
          followSet.push(new RetainOp(indexA, indexA + length, addedAttributes)) # Keep the retain
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
        followSet.push(new RetainOp(indexA, indexA + elemA.getLength()))
        indexA += elemA.getLength()
        elemIndexA++
      else if Delta.isRetain(elemA) and Delta.isInsert(elemB)
        followSet.push(elemB)
        indexB += elemB.getLength()
        elemIndexB++
      else
        console.warn("Mismatch. elemA is: " + typeof(elemA) + ", elemB is:  " + typeof(elemB))

    # Remaining loops account for different length ops, only inserts will be
    # accepted
    while elemIndexA < deltaA.ops.length
      elemA = deltaA.ops[elemIndexA]
      followSet.push(new RetainOp(indexA, indexA + elemA.getLength())) if Delta.isInsert(elemA) # retain elemA
      indexA += elemA.getLength()
      elemIndexA++

    while elemIndexB < deltaB.ops.length
      elemB = deltaB.ops[elemIndexB]
      followSet.push(elemB) if Delta.isInsert(elemB) # insert elemB
      indexB += elemB.getLength()
      elemIndexB++

    followEndLength = 0
    for elem in followSet
      followEndLength += elem.getLength()

    follow = new Delta(followStartLength, followEndLength, followSet)
    console.assert(Delta.isDelta(follow), "Follows returning invalid Delta", follow)
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
    console.assert(this.isInsertsOnly(), "Invert called on invalid delta containing non-insert ops: #{deltaA}")
    deltaA = this
    deltaC = deltaA.compose(deltaB)
    inverse = deltaA.decompose(deltaC)
    return inverse

  isEqual: (other) ->
    return false unless other
    keys = ['startLength', 'endLength', 'ops']
    return _.isEqual(_.pick(this, keys...),
                     _.pick(other, keys...))

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

  # XXX: Can we remove normalize all together? We currently seem to rely on it
  # deep copying the ops...
  normalize: ->
    normalizedOps = _.map(@ops, (op) ->
      switch typeof op
        when 'object'
          if Delta.isInsert(op)
            return new InsertOp(op.value, op.attributes)
          else if Delta.isRetain(op)
            return new RetainOp(op.start, op.end, op.attributes)
        else
          return null
    )
    @ops = _.reject(normalizedOps, (op) -> !op? || op.getLength() == 0)

  toString: ->
    return "{(#{@startLength}->#{@endLength}) [#{@ops.join(', ')}]}"


module.exports = Delta