Utils =
  maxArray: (array) ->
    # Find the max value in an array.
    Math.max.apply null, array

  trimCheck: ->
    if not String.prototype.trim
      String.prototype.trim = ->
        @replace /^\s+|\s+$/g, ''
    return