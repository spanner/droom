jQuery ($) ->
  class ApplicationFieldset
    constructor: (element) ->
      @_container = $(element)
      @_url = @_container.attr('data-url')
      @_fields = {}
      for field in ['ref', 'id', 'year', 'applicant', 'title']
        @_fields[field] = @_container.find("input[data-attribute=\"#{field}\"]")
      @_request = null
      @_cache = {}
      @_fields.ref.application_suggester()
      @_fields.ref.bind "keyup", @change
      console.log "fieldset", @_fields

    change: (e) =>
      kc = e.which
      #   delete,     backspace,    alphanumerics,    number pad,        punctuation
      if (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
        @get @_fields.ref.val()

    get: (term) =>
      @_request.abort() if @_request
      if @_cache[term]
        @match(term) 
      else
        @_request = $.get @_url + "/" + encodeURIComponent(term), (response) =>
          @_cache[term] = response || "null"
          @match(term)
    
    match: (term) =>
      if @_cache[term] is "null"
        @unmatch(term)
      else
        for field in ['id', 'year', 'applicant', 'title']
          @_fields[field].val(@_cache[term][field]).addClass('automatic')
          @_container.find("p.#{field} label").addClass('automatic')
    
    unmatch: (term) =>
      for field in ['id', 'year', 'applicant', 'title']
        @_fields[field].val("")
        @_fields[field].removeClass('automatic')
      

  $.fn.application_fieldset = () ->
    @each ->
      new ApplicationFieldset(@)


