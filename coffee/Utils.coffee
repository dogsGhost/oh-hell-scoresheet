Utils =
  transEndEventNames:
    # Hash of appropriate transitionend prefixes based on css prefix.
    'WebkitTransition' : 'webkitTransitionEnd'
    'MozTransition'    : 'transitionend'
    'OTransition'      : 'oTransitionEnd'
    'msTransition'     : 'MSTransitionEnd'
    'transition'       : 'transitionend'

  transEndEventName: ->
    # Check which prefix to use.
    if Modernizr.csstransitions
      @transEndEventNames[Modernizr.prefixed('transition')]
    else
      ''

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
    # Removes an element from the page when css transition ends.
    if @transEndEventName()
      $el.on @transEndEventName(), -> $el.remove()

  transitionTrigger: ($el) ->
    # This is what starts the transition event.
    if @transEndEventName()
      $el.addClass 'hide'

  transitionFallback: ($el, callback) ->
    # Fallback for non-support of transitionend event.
    if not @transEndEventName()
      $el.slideUp 400, -> 
        $el.remove() if callback