jQuery ($) ->

  $.fn.stream_link = () ->
    $.stream ?= new Stream('#streamer')
    @each ->
      $.stream.fetch(@href)
      $(@).click (e) ->
        e.preventDefault() if e
        $.stream.display(@href)


  class Stream
    @scraps: {}
      
    constructor: (element) ->
      @_container = $(element)
      @_container.bind 'open', @show
      @_container.bind 'close', @hide
      @_container.bind 'resize', @place
      @_container.bind 'mousedown', @containEvent
      @_container.bind 'touchstart', @containEvent
      
    containEvent: (e) =>
      e.stopPropagation() if e
      
    display: (url) =>
      if scrap = Stream.scraps[url]
        @reveal(scrap)
      else
        @fetch(url, @reveal)

    fetch: (url, callback) =>
      unless Stream.scraps[url]?
        $.ajax
          url: url
          dataType: 'html'
          success: (response) =>
            scrap = new Scrap(response)
            Stream.scraps[url] = scrap
            callback?(scrap)

    reveal: (scrap) =>
      @_container.html scrap.getContent()
      @_container.activate()
      @show()
      
    show: () =>
      unless @_showing
        @_container.fadeIn()
        @_showing = true
        $(document).bind 'mousedown', @hide
        $(document).bind 'touchstart', @hide
    
    hide: () =>
      if @_showing
        @_container.fadeOut()
        @_showing = false
        $(document).unbind 'mousedown', @hide
        $(document).unbind 'touchstart', @hide
    
    width: () =>
      @_container.width()

    height: () =>
      @_container.height()



  class Scrap
    constructor: (html) ->
      @_container = $('<div class="scrap_holder" />')
      @_container.html(html)
      @_container.css
        width: $.stream.width()
        height: $.stream.height()

    getContent: () =>
      @_container
















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
