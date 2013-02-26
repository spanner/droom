jQuery ($) ->
  $.fn.scrap_form = () ->
    @each ->
      new ScrapForm(@)
    @

  $.fn.type_setter = (scrapform) ->
    @change ->
      console.log "change!", @
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
      @setType()
    
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
          @textBased()
        when "image"
          @imageBased()
        when "event"
          @eventBased()
      
    imageBased: () =>
      @_image.show().find('input').prop('disabled', false);
      @_event.hide().find('input').prop('disabled', true);
      @_body.hide().find('input, textarea').prop('disabled', true);

    textBased: () =>
      @_image.hide().find('input').prop('disabled', true);
      @_event.hide().find('input').prop('disabled', true);
      @_body.show().find('input, textarea').prop('disabled', false);

    eventBased: () =>
      @_image.hide().find('input').prop('disabled', true);
      @_event.show().find('input').prop('disabled', false);
      @_body.hide().find('input, textarea').prop('disabled', true);
        