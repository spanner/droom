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
      
    imageBased: () =>
      @_image.find('input').prop('disabled', false);
      @_image.show()
      @_body.hide()

    textBased: () =>
      @_image.find('input').prop('disabled', true);
      @_image.hide()
      @_body.show()
        