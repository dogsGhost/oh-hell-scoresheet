Utils =
  transitionEnd: ''

  transitionCheck: ->
    # Test for transition support.
    el = document.getElementById 'container'
    if el.style.transitionDelay is ''
      @transitionEnd = 'transitionend'
      return
    else if el.style.WebkitTransitionDelay is ''
      @transitionEnd = 'webkitTransitionEnd'
      return

  maxArray: (array) ->
    # Find the max value in an array.
    Math.max.apply null, array

  trimCheck: ->
    # Add trim method for IE8
    if not String.prototype.trim
      String.prototype.trim = ->
        @replace /^\s+|\s+$/g, ''
    return

  transitionCallback: ($el) ->
    # Removes an element from the page with css transition ends.
    if @transitionEnd
      $el.on @transitionEnd, -> $el.remove()
    else
      # IE fallback here.
      # Something like:
      # $el.slideUp 400, -> $el.remove()
      # But for now:
      window.alert 'Sorry, this browser is currently not supported.'
    