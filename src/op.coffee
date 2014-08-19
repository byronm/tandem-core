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

_ = require('lodash')

class Op
  @isInsert: (i) ->
    return i? && typeof i.value == "string"

  @isRetain: (r) ->
    return r? && typeof r.start == "number" && typeof r.end == "number"

  constructor: (attributes = {}) ->
    @attributes = _.clone(attributes)

  addAttributes: (attributes) ->
    addedAttributes = {}
    for key, value of attributes when @attributes[key] == undefined
      addedAttributes[key] = value
    return addedAttributes

  attributesMatch: (other) ->
    otherAttributes = other.attributes || {}
    return _.isEqual(@attributes, otherAttributes)

  composeAttributes: (attributes) ->
    resolveAttributes = (oldAttrs, newAttrs) =>
      return oldAttrs if !newAttrs
      resolvedAttrs = _.clone(oldAttrs)
      for key, value of newAttrs
        if Op.isInsert(this) and value == null
          delete resolvedAttrs[key]
        else if typeof value != 'undefined'
          if (typeof resolvedAttrs[key] == 'object' and
              typeof value == 'object' and
              _.all([resolvedAttrs[key], newAttrs[key]], ((val) -> val != null)))
            resolvedAttrs[key] = resolveAttributes(resolvedAttrs[key], value)
          else
            resolvedAttrs[key] = value
      return resolvedAttrs
    return resolveAttributes(@attributes, attributes)

  numAttributes: ->
    _.keys(@attributes).length

  printAttributes: ->
    return JSON.stringify(@attributes)


module.exports = Op
