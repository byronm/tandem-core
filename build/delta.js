(function() {
  var Delta, InsertOp, Op, RetainOp, diff_match_patch, dmp, _;

  _ = require('underscore')._;

  diff_match_patch = require('./diff_match_patch');

  Op = require('./op');

  InsertOp = require('./insert');

  RetainOp = require('./retain');

  dmp = new diff_match_patch();

  Delta = (function() {
    var _insertInsertCase, _retainRetainCase;

    Delta.getIdentity = function(length) {
      return new Delta(length, length, [new RetainOp(0, length)]);
    };

    Delta.getInitial = function(contents) {
      return new Delta(0, contents.length, [new InsertOp(contents)]);
    };

    Delta.isDelta = function(delta) {
      var op, _i, _len, _ref;
      if ((delta != null) && typeof delta === "object" && typeof delta.startLength === "number" && typeof delta.endLength === "number" && typeof delta.ops === "object") {
        _ref = delta.ops;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          op = _ref[_i];
          if (!(Op.isRetain(op) || Op.isInsert(op))) {
            return false;
          }
        }
        return true;
      }
      return false;
    };

    Delta.makeDelta = function(obj) {
      return new Delta(obj.startLength, obj.endLength, _.map(obj.ops, function(op) {
        if (Op.isInsert(op)) {
          return new InsertOp(op.value, op.attributes);
        } else if (Op.isRetain(op)) {
          return new RetainOp(op.start, op.end, op.attributes);
        } else {
          return null;
        }
      }));
    };

    Delta.makeDeleteDelta = function(startLength, index, length) {
      var ops;
      ops = [];
      if (0 < index) {
        ops.push(new RetainOp(0, index));
      }
      if (index + length < startLength) {
        ops.push(new RetainOp(index + length, startLength));
      }
      return new Delta(startLength, ops);
    };

    Delta.makeInsertDelta = function(startLength, index, value, attributes) {
      var ops;
      ops = [new InsertOp(value, attributes)];
      if (0 < index) {
        ops.unshift(new RetainOp(0, index));
      }
      if (index < startLength) {
        ops.push(new RetainOp(index, startLength));
      }
      return new Delta(startLength, ops);
    };

    Delta.makeRetainDelta = function(startLength, index, length, attributes) {
      var ops;
      ops = [new RetainOp(index, index + length, attributes)];
      if (0 < index) {
        ops.unshift(new RetainOp(0, index));
      }
      if (index + length < startLength) {
        ops.push(new RetainOp(index + length, startLength));
      }
      return new Delta(startLength, ops);
    };

    function Delta(startLength, endLength, ops) {
      var length;
      this.startLength = startLength;
      this.endLength = endLength;
      this.ops = ops;
      if (this.ops == null) {
        this.ops = this.endLength;
        this.endLength = null;
      }
      this.ops = _.map(this.ops, function(op) {
        if (Op.isRetain(op)) {
          return op;
        } else if (Op.isInsert(op)) {
          return op;
        } else {
          throw new Error("Creating delta with invalid op. Expecting an insert or retain.");
        }
      });
      this.compact();
      length = _.reduce(this.ops, function(count, op) {
        return count + op.getLength();
      }, 0);
      if ((this.endLength != null) && length !== this.endLength) {
        throw new Error("Expecting end length of " + length);
      } else {
        this.endLength = length;
      }
    }

    Delta.prototype.apply = function(insertFn, deleteFn, applyAttrFn, context) {
      var index, offset, retains,
        _this = this;
      if (insertFn == null) {
        insertFn = (function() {});
      }
      if (deleteFn == null) {
        deleteFn = (function() {});
      }
      if (applyAttrFn == null) {
        applyAttrFn = (function() {});
      }
      if (context == null) {
        context = null;
      }
      if (this.isIdentity()) {
        return;
      }
      index = 0;
      offset = 0;
      retains = [];
      _.each(this.ops, function(op) {
        if (Op.isInsert(op)) {
          insertFn.call(context, index + offset, op.value, op.attributes);
          return offset += op.getLength();
        } else if (Op.isRetain(op)) {
          if (op.start > index) {
            deleteFn.call(context, index + offset, op.start - index);
            offset -= op.start - index;
          }
          retains.push(new RetainOp(op.start + offset, op.end + offset, op.attributes));
          return index = op.end;
        }
      });
      if (this.endLength < this.startLength + offset) {
        deleteFn.call(context, this.endLength, this.startLength + offset - this.endLength);
      }
      return _.each(retains, function(op) {
        _.each(op.attributes, function(value, format) {
          if (value === null) {
            return applyAttrFn.call(context, op.start, op.end - op.start, format, value);
          }
        });
        return _.each(op.attributes, function(value, format) {
          if (value != null) {
            return applyAttrFn.call(context, op.start, op.end - op.start, format, value);
          }
        });
      });
    };

    Delta.prototype.applyToText = function(text) {
      var appliedText, delta, op, result, _i, _len, _ref;
      delta = this;
      if (text.length !== delta.startLength) {
        throw new Error("Start length of delta: " + delta.startLength + " is not equal to the text: " + text.length);
      }
      appliedText = [];
      _ref = delta.ops;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        op = _ref[_i];
        if (Op.isInsert(op)) {
          appliedText.push(op.value);
        } else {
          appliedText.push(text.substring(op.start, op.end));
        }
      }
      result = appliedText.join("");
      if (delta.endLength !== result.length) {
        throw new Error("End length of delta: " + delta.endLength + " is not equal to result text: " + result.length);
      }
      return result;
    };

    Delta.prototype.canCompose = function(delta) {
      return Delta.isDelta(delta) && this.endLength === delta.startLength;
    };

    Delta.prototype.compact = function() {
      var compacted;
      compacted = [];
      _.each(this.ops, function(op) {
        var last;
        if (op.getLength() === 0) {
          return;
        }
        if (compacted.length === 0) {
          return compacted.push(op);
        } else {
          last = _.last(compacted);
          if (Op.isInsert(last) && Op.isInsert(op) && last.attributesMatch(op)) {
            return compacted[compacted.length - 1] = new InsertOp(last.value + op.value, op.attributes);
          } else if (Op.isRetain(last) && Op.isRetain(op) && last.end === op.start && last.attributesMatch(op)) {
            return compacted[compacted.length - 1] = new RetainOp(last.start, op.end, op.attributes);
          } else {
            return compacted.push(op);
          }
        }
      });
      return this.ops = compacted;
    };

    Delta.prototype.compose = function(deltaB) {
      var composed, deltaA, opInB, opsInRange, _i, _len, _ref;
      if (!this.canCompose(deltaB)) {
        throw new Error('Cannot compose delta');
      }
      deltaA = this;
      composed = [];
      _ref = deltaB.ops;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        opInB = _ref[_i];
        if (Op.isInsert(opInB)) {
          composed.push(opInB);
        } else if (Op.isRetain(opInB)) {
          opsInRange = deltaA.getOpsAt(opInB.start, opInB.getLength());
          opsInRange = _.map(opsInRange, function(opInA) {
            if (Op.isInsert(opInA)) {
              return new InsertOp(opInA.value, opInA.composeAttributes(opInB.attributes));
            } else {
              return new RetainOp(opInA.start, opInA.end, opInA.composeAttributes(opInB.attributes));
            }
          });
          composed = composed.concat(opsInRange);
        } else {
          throw new Error('Invalid op in deltaB when composing');
        }
      }
      return new Delta(deltaA.startLength, deltaB.endLength, composed);
    };

    Delta.prototype.decompose = function(deltaA) {
      var decomposeAttributes, deltaB, deltaC, insertDelta, offset, ops;
      deltaC = this;
      if (!Delta.isDelta(deltaA)) {
        throw new Error("Decompose called when deltaA is not a Delta, type: " + typeof deltaA);
      }
      if (deltaA.startLength !== this.startLength) {
        throw new Error("startLength " + deltaA.startLength + " / startLength " + this.startLength + " mismatch");
      }
      if (!_.all(deltaA.ops, (function(op) {
        return Op.isInsert(op);
      }))) {
        throw new Error("DeltaA has retain in decompose");
      }
      if (!_.all(deltaC.ops, (function(op) {
        return Op.isInsert(op);
      }))) {
        throw new Error("DeltaC has retain in decompose");
      }
      decomposeAttributes = function(attrA, attrC) {
        var decomposedAttributes, key, value;
        decomposedAttributes = {};
        for (key in attrC) {
          value = attrC[key];
          if (attrA[key] === void 0 || attrA[key] !== value) {
            if (attrA[key] !== null && typeof attrA[key] === 'object' && value !== null && typeof value === 'object') {
              decomposedAttributes[key] = decomposeAttributes(attrA[key], value);
            } else {
              decomposedAttributes[key] = value;
            }
          }
        }
        for (key in attrA) {
          value = attrA[key];
          if (attrC[key] === void 0) {
            decomposedAttributes[key] = null;
          }
        }
        return decomposedAttributes;
      };
      insertDelta = deltaA.diff(deltaC);
      ops = [];
      offset = 0;
      _.each(insertDelta.ops, function(op) {
        var offsetC, opsInC;
        opsInC = deltaC.getOpsAt(offset, op.getLength());
        offsetC = 0;
        _.each(opsInC, function(opInC) {
          var d, offsetA, opsInA;
          if (Op.isInsert(op)) {
            d = new InsertOp(op.value.substring(offsetC, offsetC + opInC.getLength()), opInC.attributes);
            ops.push(d);
          } else if (Op.isRetain(op)) {
            opsInA = deltaA.getOpsAt(op.start + offsetC, opInC.getLength());
            offsetA = 0;
            _.each(opsInA, function(opInA) {
              var attributes, e, start;
              attributes = decomposeAttributes(opInA.attributes, opInC.attributes);
              start = op.start + offsetA + offsetC;
              e = new RetainOp(start, start + opInA.getLength(), attributes);
              ops.push(e);
              return offsetA += opInA.getLength();
            });
          } else {
            throw new Error("Invalid delta in deltaB when composing");
          }
          return offsetC += opInC.getLength();
        });
        return offset += op.getLength();
      });
      deltaB = new Delta(insertDelta.startLength, insertDelta.endLength, ops);
      return deltaB;
    };

    Delta.prototype.diff = function(other) {
      var diff, finalLength, insertDelta, operation, ops, originalLength, textA, textC, value, _i, _len, _ref, _ref1;
      _ref = _.map([this, other], function(delta) {
        return _.map(delta.ops, function(op) {
          if (op.value != null) {
            return op.value;
          } else {
            return "";
          }
        }).join('');
      }), textA = _ref[0], textC = _ref[1];
      if (!(textA === '' && textC === '')) {
        diff = dmp.diff_main(textA, textC);
        if (diff.length <= 0) {
          throw new Error("diffToDelta called with diff with length <= 0");
        }
        originalLength = 0;
        finalLength = 0;
        ops = [];
        for (_i = 0, _len = diff.length; _i < _len; _i++) {
          _ref1 = diff[_i], operation = _ref1[0], value = _ref1[1];
          switch (operation) {
            case diff_match_patch.DIFF_DELETE:
              originalLength += value.length;
              break;
            case diff_match_patch.DIFF_INSERT:
              ops.push(new InsertOp(value));
              finalLength += value.length;
              break;
            case diff_match_patch.DIFF_EQUAL:
              ops.push(new RetainOp(originalLength, originalLength + value.length));
              originalLength += value.length;
              finalLength += value.length;
          }
        }
        insertDelta = new Delta(originalLength, finalLength, ops);
      } else {
        insertDelta = new Delta(0, 0, []);
      }
      return insertDelta;
    };

    _insertInsertCase = function(elemA, elemB, indexes, aIsRemote) {
      var length, results;
      results = _.extend({}, indexes);
      length = Math.min(elemA.getLength(), elemB.getLength());
      if (aIsRemote) {
        results.transformOp = new RetainOp(results.indexA, results.indexA + length);
        results.indexA += length;
        if (length === elemA.getLength()) {
          results.elemIndexA++;
        } else if (length < elemA.getLength()) {
          results.elemA = _.last(elemA.split(length));
        } else {
          throw new Error("Invalid elem length in transform");
        }
      } else {
        results.transformOp = _.first(elemB.split(length));
        results.indexB += length;
        if (length === elemB.getLength()) {
          results.elemIndexB++;
        } else {
          results.elemB = _.last(elemB.split(length));
        }
      }
      return results;
    };

    _retainRetainCase = function(elemA, elemB, indexes) {
      var addedAttributes, elemIndexA, elemIndexB, errMsg, indexA, indexB, length, results;
      indexA = indexes.indexA, indexB = indexes.indexB, elemIndexA = indexes.elemIndexA, elemIndexB = indexes.elemIndexB;
      results = _.extend({}, indexes);
      if (elemA.end < elemB.start) {
        results.indexA += elemA.getLength();
        results.elemIndexA++;
      } else if (elemB.end < elemA.start) {
        results.indexB += elemB.getLength();
        results.elemIndexB++;
      } else {
        if (elemA.start < elemB.start) {
          results.indexA += elemB.start - elemA.start;
          elemA = results.elemA = new RetainOp(elemB.start, elemA.end, elemA.attributes);
        } else if (elemB.start < elemA.start) {
          results.indexB += elemA.start - elemB.start;
          elemB = results.elemB = new RetainOp(elemA.start, elemB.end, elemB.attributes);
        }
        errMsg = "RetainOps must have same start length in transform";
        if (elemA.start !== elemB.start) {
          throw new Error(errMsg);
        }
        length = Math.min(elemA.end, elemB.end) - elemA.start;
        addedAttributes = elemA.addAttributes(elemB.attributes);
        results.transformOp = new RetainOp(results.indexA, results.indexA + length, addedAttributes);
        results.indexA += length;
        results.indexB += length;
        if (elemA.end === elemB.end) {
          results.elemIndexA++;
          results.elemIndexB++;
        } else if (elemA.end < elemB.end) {
          results.elemIndexA++;
          results.elemB = _.last(elemB.split(length));
        } else {
          results.elemIndexB++;
          results.elemA = _.last(elemA.split(length));
        }
      }
      if (results.elemIndexA !== indexes.elemIndexA) {
        results.elemA = null;
      }
      if (results.elemIndexB !== indexes.elemIndexB) {
        results.elemB = null;
      }
      return results;
    };

    Delta.prototype.transform = function(deltaA, aIsRemote) {
      var deltaB, elemA, elemB, elemIndexA, elemIndexB, errMsg, indexA, indexB, results, transformEndLength, transformOps, transformStartLength, _applyResults, _buildIndexes;
      if (aIsRemote == null) {
        aIsRemote = false;
      }
      if (!Delta.isDelta(deltaA)) {
        errMsg = "Transform called when deltaA is not a Delta, type: ";
        throw new Error(errMsg + typeof deltaA);
      }
      deltaA = new Delta(deltaA.startLength, deltaA.endLength, deltaA.ops);
      deltaB = new Delta(this.startLength, this.endLength, this.ops);
      transformOps = [];
      indexA = indexB = 0;
      elemIndexA = elemIndexB = 0;
      _applyResults = function(results) {
        if (results.indexA != null) {
          indexA = results.indexA;
        }
        if (results.indexB != null) {
          indexB = results.indexB;
        }
        if (results.elemIndexA != null) {
          elemIndexA = results.elemIndexA;
        }
        if (results.elemIndexB != null) {
          elemIndexB = results.elemIndexB;
        }
        if (results.elemA != null) {
          deltaA.ops[elemIndexA] = results.elemA;
        }
        if (results.elemB != null) {
          deltaB.ops[elemIndexB] = results.elemB;
        }
        if (results.transformOp != null) {
          return transformOps.push(results.transformOp);
        }
      };
      _buildIndexes = function() {
        return {
          indexA: indexA,
          indexB: indexB,
          elemIndexA: elemIndexA,
          elemIndexB: elemIndexB
        };
      };
      while (elemIndexA < deltaA.ops.length && elemIndexB < deltaB.ops.length) {
        elemA = deltaA.ops[elemIndexA];
        elemB = deltaB.ops[elemIndexB];
        if (Op.isInsert(elemA) && Op.isInsert(elemB)) {
          results = _insertInsertCase(elemA, elemB, _buildIndexes(), aIsRemote);
          _applyResults(results);
        } else if (Op.isRetain(elemA) && Op.isRetain(elemB)) {
          results = _retainRetainCase(elemA, elemB, _buildIndexes());
          _applyResults(results);
        } else if (Op.isInsert(elemA) && Op.isRetain(elemB)) {
          transformOps.push(new RetainOp(indexA, indexA + elemA.getLength()));
          indexA += elemA.getLength();
          elemIndexA++;
        } else if (Op.isRetain(elemA) && Op.isInsert(elemB)) {
          transformOps.push(elemB);
          indexB += elemB.getLength();
          elemIndexB++;
        }
      }
      while (elemIndexA < deltaA.ops.length) {
        elemA = deltaA.ops[elemIndexA];
        if (Op.isInsert(elemA)) {
          transformOps.push(new RetainOp(indexA, indexA + elemA.getLength()));
        }
        indexA += elemA.getLength();
        elemIndexA++;
      }
      while (elemIndexB < deltaB.ops.length) {
        elemB = deltaB.ops[elemIndexB];
        if (Op.isInsert(elemB)) {
          transformOps.push(elemB);
        }
        indexB += elemB.getLength();
        elemIndexB++;
      }
      transformStartLength = deltaA.endLength;
      transformEndLength = _.reduce(transformOps, function(transformEndLength, op) {
        return transformEndLength + op.getLength();
      }, 0);
      return new Delta(transformStartLength, transformEndLength, transformOps);
    };

    Delta.prototype.getOpsAt = function(index, length) {
      var changes, getLength, offset, op, opLength, start, _i, _len, _ref;
      changes = [];
      if ((this.savedOpOffset != null) && this.savedOpOffset < index) {
        offset = this.savedOpOffset;
      } else {
        offset = this.savedOpOffset = this.savedOpIndex = 0;
      }
      _ref = this.ops.slice(this.savedOpIndex);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        op = _ref[_i];
        if (offset >= index + length) {
          break;
        }
        opLength = op.getLength();
        if (index < offset + opLength) {
          start = Math.max(index - offset, 0);
          getLength = Math.min(opLength - start, index + length - offset - start);
          changes.push(op.getAt(start, getLength));
        }
        offset += opLength;
        this.savedOpIndex += 1;
        this.savedOpOffset += opLength;
      }
      return changes;
    };

    Delta.prototype.invert = function(deltaB) {
      var deltaA, deltaC, inverse;
      if (!this.isInsertsOnly()) {
        throw new Error("Invert called on invalid delta containing non-insert ops");
      }
      deltaA = this;
      deltaC = deltaA.compose(deltaB);
      inverse = deltaA.decompose(deltaC);
      return inverse;
    };

    Delta.prototype.isEqual = function(other) {
      if (!other) {
        return false;
      }
      if (this.startLength !== other.startLength || this.endLength !== other.endLength) {
        return false;
      }
      if (!_.isArray(other.ops) || this.ops.length !== other.ops.length) {
        return false;
      }
      return _.all(this.ops, function(op, i) {
        return op.isEqual(other.ops[i]);
      });
    };

    Delta.prototype.isIdentity = function() {
      var index, op, _i, _len, _ref;
      if (this.startLength === this.endLength) {
        if (this.ops.length === 0) {
          return true;
        }
        index = 0;
        _ref = this.ops;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          op = _ref[_i];
          if (!Op.isRetain(op)) {
            return false;
          }
          if (op.start !== index) {
            return false;
          }
          if (!(op.numAttributes() === 0 || (op.numAttributes() === 1 && _.has(op.attributes, 'authorId')))) {
            return false;
          }
          index = op.end;
        }
        if (index !== this.endLength) {
          return false;
        }
        return true;
      }
      return false;
    };

    Delta.prototype.isInsertsOnly = function() {
      return _.every(this.ops, function(op) {
        return Op.isInsert(op);
      });
    };

    Delta.prototype.merge = function(other) {
      var ops,
        _this = this;
      ops = _.map(other.ops, function(op) {
        if (Op.isRetain(op)) {
          return new RetainOp(op.start + _this.startLength, op.end + _this.startLength, op.attributes);
        } else {
          return op;
        }
      });
      ops = this.ops.concat(ops);
      return new Delta(this.startLength + other.startLength, ops);
    };

    Delta.prototype.split = function(index) {
      var leftOps, rightOps;
      if (!this.isInsertsOnly()) {
        throw new Error("Split only implemented for inserts only");
      }
      if (!(0 <= index && index <= this.endLength)) {
        throw new Error("Split at invalid index");
      }
      leftOps = [];
      rightOps = [];
      _.reduce(this.ops, function(offset, op) {
        var left, right, _ref;
        if (offset + op.getLength() <= index) {
          leftOps.push(op);
        } else if (offset >= index) {
          rightOps.push(op);
        } else {
          _ref = op.split(index - offset), left = _ref[0], right = _ref[1];
          leftOps.push(left);
          rightOps.push(right);
        }
        return offset + op.getLength();
      }, 0);
      return [new Delta(0, leftOps), new Delta(0, rightOps)];
    };

    Delta.prototype.toString = function() {
      return "{(" + this.startLength + "->" + this.endLength + ") [" + (this.ops.join(', ')) + "]}";
    };

    return Delta;

  })();

  module.exports = Delta;

}).call(this);
