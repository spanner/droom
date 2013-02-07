jQuery ($) ->

  ## Utilities
  # **$.makeGuid** is a neat little rfc4122 generator cribbed from 
  # http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
  #
  $.makeGuid = ()->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random()*16|0
      v = if c is 'x' then r else r & 0x3 | 0x8
      v.toString 16

  # **$.urlParam** is a query string parser used to restore history from one or more query string parameters.
  # It's regex based and deeply suspect. If you can populate and read a form field, do that instead.
  #
  $.urlParam = (name) ->
    results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(window.location.href)
    return false unless results
    results[1] or null


  # Radio buttons don't fire a change event when deselected. Here we mimic that effect
  # by firing it from any other input in that button set when it *is* selected. 
  #
  $.fn.trigger_change_on_deselect = ->
    @each ->
      input = $(@)
      name = input.attr('name')
      $("input[name='#{name}']:radio").not(input).change () ->
        input.change() if $(@).is(":checked")

  $.easing.glide = (x, t, b, c, d) ->
    -c * ((t=t/d-1)*t*t*t - 1) + b

  $.easing.boing = (x, t, b, c, d, s) ->
    s ?= 1.70158;
    c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b

  $.add_stylesheet = (path) ->
    if document.createStyleSheet
      document.createStyleSheet(path)
    else
      $('head').append("<link rel=\"stylesheet\" href=\"#{path}\" type=\"text/css\" />");

  $.namespace = (target, name, block) ->
    [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
    top = target
    target = target[item] or= {} for item in name.split '.'
    block target, top

  $.fn.find_including_self = (selector) ->
    selection = @.find(selector)
    selection.push @ if @is(selector)
    selection

  $.ajaxError = (jqXHR, textStatus, errorThrown) =>
    console.log "...error!", jqXHR, textStatus, errorThrown
    trigger "error", textStatus, errorThrown
    return

  $.fn.flash = ->
    @each ->
      container = $(this)
      container.fadeIn "fast"
      $("<a href=\"#\" class=\"closer\">close</a>").prependTo(container)
      container.bind "click", (e) ->
        e.preventDefault()
        container.fadeOut "fast"

  $.fn.disappearAfter = (interval) ->
    interval ?= 1000
    $(@).delay(interval).slideUp "slow", () ->
      $(@).remove()
    
  $.fn.signal = (color, duration) ->
    color ?= "#f7f283"
    duration ?= 1000
    @each ->
      $(@).css('backgroundColor', color).animate({'backgroundColor': '#ffffff'}, duration)
      
  $.fn.signal_confirmation = ->
    @signal('#c7ebb4')

  $.fn.signal_error = ->
    @signal('#e55a51')

  $.fn.signal_cancellation = ->
    @signal('#a2a3a3')
    
  $.fn.back_button = ->
    @click (e) ->
      e.preventDefault() if e
      history.back()
      true

  $.activations = []
  
  $.activate_with = (fn) ->
    $.activations.push fn
  
  $.fn.activate = () ->
    $.each $.activations, (i, fn) =>
      fn.apply(@)
    @
