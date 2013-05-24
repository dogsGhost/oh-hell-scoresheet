Utils =
  transitionEnd: ''

  transitionCheck: ->
    # Test for transition support.
    el = document.getElementById 'container'
    if el.style.transitionDelay is ''
      @transitionEnd = 'transitionend'
      return
    else
      @transitionEnd = 'webkitTransitionEnd'
      return

  maxArray: (array) ->
    # Find the max value in an array.
    Math.max.apply null, array

  trimCheck: ->
    if not String.prototype.trim
      String.prototype.trim = ->
        @replace /^\s+|\s+$/g, ''
    return

  transitionCallback: ($el) ->
    $el.on @transitionEnd, -> $el.remove()
    