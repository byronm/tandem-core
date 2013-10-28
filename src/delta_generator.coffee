Delta      = require('./delta')
InsertOp   = require('./insert')
RetainOp   = require('./retain')

class DeltaGenerator
  @constants =
    attributes:
      'bold'      : [true, false],
      'italic'    : [true, false],
      # 'link'    : [true, false],
      'strike'    : [true, false],
      'font-name' : ['monospace', 'serif'],
      'fore-color': ['white', 'black', 'red', 'blue', 'lime', 'teal', 'magenta', 'yellow']
      'font-size' : ['huge', 'large', 'small'],
      'back-color': ['white', 'black', 'red', 'blue', 'lime', 'teal', 'magenta', 'yellow']

    default_attribute_value:
      'back-color' : 'white',
      'fore-color' : 'black',
      'font-name'  : 'san-serif',
      'font-size'  : 'normal'

    alphabet: "abcdefghijklmnopqrstuvwxyz\n\n\n\n  "

  @getRandomString = (alphabet, length) ->
    return _.map([0..(length - 1)], ->
      return alphabet[_.random(0, alphabet.length - 1)]
    ).join('')

  @getRandomLength = ->
    rand = Math.random()
    if rand < 0.6
      return _.random(1, 2)
    else if rand < 0.8
      return _.random(3, 4)
    else if rand < 0.9
      return _.random(5, 9)
    else
      return _.random(10, 50)

  @insertAt: (delta, insertionPoint, insertions) ->
    charIndex = opIndex = 0
    for op in delta.ops
      break if charIndex == insertionPoint
      if insertionPoint < charIndex + op.getLength()
        [head, tail] = op.split(insertionPoint - charIndex)
        delta.ops.splice(opIndex, 1, head, tail)
        opIndex++
        break
      charIndex += op.getLength()
      opIndex++
    delta.ops.splice(opIndex, 0, new InsertOp(insertions))
    delta.endLength += insertions.length
    delta.compact()

  @deleteAt: (delta, deletionPoint, numToDelete) ->
    charIndex = 0
    ops = []
    for op in delta.ops
      reachedDeletionPoint = charIndex == deletionPoint or
        deletionPoint < charIndex + op.getLength()
      if numToDelete > 0 && reachedDeletionPoint
        curDelete = Math.min(numToDelete,
          op.getLength() - (deletionPoint - charIndex))
        numToDelete -= curDelete
        if Delta.isInsert(op)
          newText = op.value.substring(0, deletionPoint - charIndex) +
            op.value.substring(deletionPoint - charIndex + curDelete)
          ops.push(new InsertOp(newText)) if newText.length > 0
        else
          throw new Error("Expected retain but got #{op}") unless Delta.isRetain(op)
          head = new RetainOp(op.start, op.start + deletionPoint - charIndex,
            _.clone(op.attributes))
          tail = new RetainOp(op.start + deletionPoint - charIndex + curDelete,
            op.end, _.clone(op.attributes))
          ops.push(head) if head.start < head.end
          ops.push(tail) if tail.start < tail.end
        deletionPoint += curDelete
      else
        ops.push(op)
      charIndex += op.getLength()
    delta.ops = ops
    delta.endLength = _.reduce(ops, (length, op) ->
      return length + op.getLength()
    , 0)

  splitOpInThree = (elem, splitAt, length, reference) ->
    if Delta.isInsert(elem)
      headStr = elem.value.substring(0, splitAt)
      head = new InsertOp(headStr, _.clone(elem.attributes))
      curStr = elem.value.substring(splitAt, splitAt + length)
      cur = new InsertOp(curStr, _.clone(elem.attributes))
      tailStr = elem.value.substring(splitAt + length)
      tail = new InsertOp(tailStr, _.clone(elem.attributes))
      # Sanitize for \n's, which we don't want to format
      if curStr.indexOf('\n') != -1
        newCur = curStr.substring(0, curStr.indexOf('\n'))
        tailStr = curStr.substring(curStr.indexOf('\n')) + tailStr
        cur = new InsertOp(newCur, _.clone(elem.attributes))
        tail = new InsertOp(tailStr, _.clone(elem.attributes))
    else 
      throw new Error("Expected retain but got #{elem}") unless Delta.isRetain(elem)
      head = new RetainOp(elem.start, elem.start + splitAt,
        _.clone(elem.attributes))
      cur = new RetainOp(head.end, head.end + length, _.clone(elem.attributes))
      tail = new RetainOp(cur.end, elem.end, _.clone(elem.attributes))
      origOps = reference.getOpsAt(cur.start, cur.getLength())
      throw new Error("Non insert op in backref") unless _.every(origOps, (op) -> Delta.isInsert(op))
      marker = cur.start
      for op in origOps
        if Delta.isInsert(op)
          if op.value.indexOf('\n') != -1
            cur = new RetainOp(cur.start, marker + op.value.indexOf('\n'),
              _.clone(cur.attributes))
            tail = new RetainOp(marker + op.value.indexOf('\n'), tail.end,
              _.clone(tail.attributes))
            break
          else
            marker += op.getLength()
        else
          throw new Error("Got retainOp in reference delta!")
    return [head, cur, tail]

  limitScope = (op, tail, attr, referenceOps) ->
    length = 0
    val = referenceOps[0].attributes[attr]
    for refOp in referenceOps
      if refOp.attributes[attr] != val
        op.end = op.start + length
        tail.start = op.end
        break
      else
        length += refOp.getLength()

  formatBooleanAttribute = (op, tail, attr, reference) ->
    if Delta.isInsert(op)
      if op.attributes[attr]?
        delete op.attributes[attr]
      else
        op.attributes[attr] = true
    else
      throw new Error("Expected retain but got #{op}") unless Delta.isRetain(op)
      if op.attributes[attr]?
        delete op.attributes[attr]
      else
        referenceOps = reference.getOpsAt(op.start, op.getLength())
        throw new Error("Formatting a retain that does not refer to an insert.") unless _.every(referenceOps, (op) -> Delta.isInsert(op))
        if referenceOps.length > 0
          limitScope(op, tail, attr, referenceOps)
          if referenceOps[0].attributes[attr]?
            throw new Error("Boolean attribute on reference delta should only be true!") unless referenceOps[0].attributes[attr]
            op.attributes[attr] = null
          else
            op.attributes[attr] = true

  formatNonBooleanAttribute = (op, tail, attr, reference) =>
    getNewAttrVal = (prevVal) =>
      if prevVal?
        _.first(_.shuffle(_.without(@constants.attributes[attr], prevVal)))
      else
        _.first(_.shuffle(_.without(@constants.attributes[attr], @constants.default_attribute_value[attr])))

    if Delta.isInsert(op)
      op.attributes[attr] = getNewAttrVal(attr, op.attributes[attr])
    else
      throw new Error("Expected retain but got #{op}") unless Delta.isRetain(op)
      referenceOps = reference.getOpsAt(op.start, op.getLength())
      throw new Error("Formatting a retain that does not refer to an insert.") unless _.every(referenceOps, (op) -> Delta.isInsert(op))
      if referenceOps.length > 0
        limitScope(op, tail, attr, referenceOps)
        if op.attributes[attr]? and Math.random() < 0.5
            delete op.attributes[attr]
        else
          op.attributes[attr] = getNewAttrVal(op.attributes[attr])

  @formatAt: (delta, formatPoint, numToFormat, attrs, reference) ->
    charIndex = 0
    ops = []
    for op in delta.ops
      reachedFormatPoint = charIndex == formatPoint ||
        charIndex + op.getLength() > formatPoint
      if numToFormat > 0 && reachedFormatPoint
        curFormat = Math.min(numToFormat,
          op.getLength() - (formatPoint - charIndex))
        numToFormat -= curFormat
        # Need a reference to cur, the subpart of the op we want to format
        [head, cur, tail] = splitOpInThree(op, formatPoint - charIndex,
          curFormat, reference)
        ops.push(head)
        ops.push(cur)
        ops.push(tail)
        for attr in attrs
          switch attr
            when 'bold', 'italic', 'underline', 'strike', 'link'
              formatBooleanAttribute(cur, tail, attr, reference)
            when 'font-size', 'font-name', 'fore-color', 'back-color'
              formatNonBooleanAttribute(cur, tail, attr, reference)
            else
              throw new Error("Received unknown attribute: #{attr}")
        formatPoint += curFormat
      else
        ops.push(op)
      charIndex += op.getLength()

    delta.endLength = _.reduce(ops, (length, delta) ->
      return length + delta.getLength()
    , 0)
    delta.ops = ops
    delta.compact()

  @addRandomOp: (newDelta, referenceDelta) ->
    finalIndex = referenceDelta.endLength - 1
    opIndex = _.random(0, finalIndex)
    rand = Math.random()
    if rand < 0.5
      opLength = @getRandomLength()
      this.insertAt(newDelta,
                    opIndex,
                    @getRandomString(@constants.alphabet, opLength))
    else if rand < 0.75
      return newDelta if referenceDelta.endLength <= 1
      # Scribe doesn't like us deleting the final \n
      opIndex = _.random(0, finalIndex - 1)
      opLength = _.random(1, finalIndex - opIndex)
      this.deleteAt(newDelta, opIndex, opLength)
    else
      shuffled_attrs = _.shuffle(_.keys(@constants.attributes))
      numAttrs = _.random(1, shuffled_attrs.length)
      attrs = shuffled_attrs.slice(0, numAttrs)
      opLength = _.random(1, finalIndex - opIndex)
      this.formatAt(newDelta, opIndex, opLength, attrs, referenceDelta)
    return newDelta

  @getRandomDelta: (referenceDelta, numOps) ->
    newDelta = new Delta(referenceDelta.endLength,
                         referenceDelta.endLength,
                         [new RetainOp(0, referenceDelta.endLength)])
    numOps or= _.random(1, 10)
    for i in [0...numOps]
      @addRandomOp(newDelta, referenceDelta)
    return newDelta

module.exports = DeltaGenerator
