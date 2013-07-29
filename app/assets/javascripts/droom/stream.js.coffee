jQuery ($) ->

  $.fn.add_to_stream = ->
    if @length
      $.stream ?= new Streamer()
      $.stream.append(@) 

  class Streamer
    constructor: () ->
      @_container = $('<div class="streamer" />').appendTo $('body')
      @_scroller = $('<div class="scroller" />').appendTo @_container
      $('<a class="next" href="#" />').appendTo(@_container).click @next
      $('<a class="prev" href="#" />').appendTo(@_container).click @prev
      $('<a class="closer" href="#" />').appendTo(@_container).click @hide
      @_scraps = []
      @_showing = false
      @_modified = true
      @place()
      @_container.bind "mousedown", @containEvent
      @_container.bind "touchstart", @containEvent
      $(window).bind "resize", @place
    
    place: (e) =>
      w = $(window)
      @_container.css
        left: (w.width() - @_container.width()) / 2
        top: (w.height() - @_container.height())/ 2
      
    containEvent: (e) =>
      e.stopPropagation() if e
      
    append: (elements) =>
      $(elements).each (i, element) =>
        scrap = new Scrap element, this
        scrap.container.removeClass('preload').appendTo @_scroller
        @_scraps.push scrap
      @_modified = true
    
    goto: (scrap) =>
      @_swipe.slide @_scraps.indexOf(scrap)
    
    next: () =>
      @_swipe.next()

    prev: () =>
      @_swipe.prev()
      
    resetSwipe: () =>
      @_swipe?.kill()
      @_swipe = new Swipe @_container[0],
        speed: 1000
        auto: false
        loop: false
      $.swipe = @_swipe
      @_modified = false
      
    show: (scrap) =>
      unless @_showing
        @_container.fadeIn 'fast', () =>
          @resetSwipe() if @_modified
          @goto(scrap) if scrap?
        @_showing = true
        $(document).bind "mousedown", @hide
        $(document).bind "touchstart", @hide

    hide: () =>
      if @_showing
        @_container.fadeOut('fast')
        $(document).unbind "mousedown", @hide
        $(document).unbind "touchstart", @hide
        @_showing = false


  class Scrap
    constructor: (element, stream) ->
      @container = $(element)
      @_stream = stream
      $('a[data-scrap="' + @container.attr('data-scrap') + '"]').click @goto
    
    goto: (e) =>
      if e
        e.preventDefault()
        e.stopPropagation()
      @_stream.show(this)





  $.fn.scrap_form = () ->
    @each ->
      new ScrapForm(@)
    @

  class ScrapForm
    constructor: (element) ->
      @_container = $(element)
      @_header = @_container.find('.scraptypes')
      @_header.find('input:radio').change @setType
      @setType()

    setType: () =>
      scraptype = @_header.find('input:radio:checked').val()
      @_container.attr("class", "scrap #{scraptype}")

















