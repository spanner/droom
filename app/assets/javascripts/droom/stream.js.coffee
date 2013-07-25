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
      @showing = false
      @_container.bind "mousedown", @containEvent
      @_container.bind "touchstart", @containEvent
    
    containEvent: (e) =>
      e.stopPropagation() if e
      
    append: (elements) =>
      $(elements).each (i, element) =>
        scrap = new Scrap element, this
        scrap.container.removeClass('preload').appendTo @_scroller
        @_scraps.push scrap
    
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
      
    show: (scrap) =>
      unless @_showing
        @_container.fadeIn 'fast', () =>
          @resetSwipe()
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
      e.preventDefault() if e
      @_stream.show(this)
















  $.fn.scrap_form = () ->
    @each ->
      new ScrapForm(@)
    @

  $.fn.type_setter = (scrapform) ->
    @change ->
      if $(@).is('checked')
        scrapform.setType($(@).val())






  class ScrapForm
    constructor: (element) ->
      @_container = $(element)
      @_header = @_container.find('.scraptypes')
      @_fields = @_container.find('.fields')
      @_header.find('input:radio').change @setType
      @_body = @_fields.find('.body')
      @_caption = @_fields.find('.caption')
      @_image = @_fields.find('.upload')
      @_event = @_fields.find('.scrapevent')
      @_document = @_fields.find('.scrapdocument')
      @_video = @_fields.find('.scrapvideo')
      @_video.find('input').video_picker()
      @_thumb = @_video.find '.thumb'
      @setType()
      @getVideo()

    getVideo: =>
      if @_header.find('input:radio:checked').val() == "video"
        yt_id = @_video.find('input.name').val()
        $.ajax
          url: "/videos/#{yt_id}.js"
          type: "GET"
          dataType: "html"
          success: (data) =>
            @_thumb.append data

    setType: () =>
      scraptype = @_header.find('input:radio:checked').val()
      @_fields.attr("class", "fields #{scraptype}")
      switch scraptype
        when "text"
          @_body.find('textarea').attr("placeholder", "Your remarks")
          @textBased()
        when "quote"
          @_body.find('textarea').attr("placeholder", "Quote text")
          @textBased()
        when "link"
          @_body.find('textarea').attr("placeholder", "Link address")
          @textBased()
        when "video"
          @_body.find('textarea').attr("placeholder", "Youtube ID")
          @videoBased()
        when "image"
          @imageBased()
        when "event"
          @eventBased()
        when "document"
          @documentBased()

    imageBased: =>
      @_image.show().find('input').prop('disabled', false)
      @_document.remove().find('input').prop('disabled', true)
      @_event.hide().find('input').prop('disabled', true)
      @_body.hide().find('input, textarea').prop('disabled', true)

    textBased: =>
      @_image.hide().find('input').prop('disabled', true)
      @_document.remove().find('input').prop('disabled', true)
      @_event.hide().find('input').prop('disabled', true)
      @_body.show().find('input, textarea').prop('disabled', false)

    eventBased: =>
      @_image.hide().find('input').prop('disabled', true)
      @_document.remove().find('input').prop('disabled', true)
      @_event.show().find('input').prop('disabled', false)
      @_body.hide().find('input, textarea').prop('disabled', true)

    documentBased: =>
      @_image.hide().find('input').prop('disabled', true)
      @_fields.prepend @_document
      @_document = @_fields.find('.scrapdocument').activate()
      @_document.show().find('input').prop('disabled', false)
      @_event.hide().find('input').prop('disabled', true)
      @_body.hide().find('input, textarea').prop('disabled', true)

    videoBased: =>
      @_image.hide().find('input').prop('disabled', true)
      @_document.remove().find('input').prop('disabled', true)
      @_event.hide().find('input').prop('disabled', true)
      @_body.hide().find('input, textarea').prop('disabled', false)
