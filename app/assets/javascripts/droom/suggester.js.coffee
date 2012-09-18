jQuery ($) ->

  #    The Suggester is a polymorphic suggestion engine able to support any number of object types
  #    without really knowing what they are.
  #    
  #    * calling
  #    * data structure
  #    * object types
  #  
  $.fn.suggestible = (options) ->
    options = $.extend(
      submit_form: true
      threshold: 3
    , options)
    @each ->
      new Suggester(@, options)
    @

  class Suggester
    constructor: (element, options) ->
      @prompt = $(element)
      @form = @prompt.parents("form")
      if options.type
        @url = "/suggestions/#{options.type}"
      else
        @url = "/suggestions"
      @options = $.extend(
        url: @url
        fill_field: true
        empty_field: false
        submit_form: false
        threshold: 2
        afterSuggest: null
        afterSelect: null
      , options)
      @container = $("<ul class=\"suggestions\"></ul>").appendTo(@prompt.offsetParent())
      @button = @form.find("a.search")
      @previously = null
      @request = null
      @visible = false
      @suggestions = []
      @suggestion = null
      @cache = {}
      @blanks = []
      
      @prompt.keyup @key
      @form.submit @hide
      @
      
    place: () =>
      @container.css
        top: @prompt.position().top + @prompt.outerHeight() - 2
        left: @prompt.position().left
        width: @prompt.outerWidth() - 2

    reset: () =>
      @container.empty()
      @suggestions = []
      @suggestion = null

    pend: () =>
      @place()
      @reset()
      @button.addClass "waiting"

    get: (e) =>
      @pend()
      query = @prompt.val()
      if query.length >= @options.threshold and query isnt @previously
        if @cache[query]
          @suggest @cache[query]
        else if @previously_blank(query)
          @suggest []
        else
          @request.abort()  if @request
          @request = $.getJSON(@options.url, "term=" + encodeURIComponent(query), (suggestions) =>
            @cache[query] = suggestions
            @blanks.push query  if suggestions.length is 0
            @suggest suggestions
          )
      else
        @hide()

    suggest: (suggestions) =>
      @button.removeClass "waiting"
      @show()
      if suggestions.length > 0
        $.each suggestions, (i, suggestion) =>
          link = $("<a href=\"#\" class=\"" + suggestion.type + "\">" + suggestion.text + "</a>")
          link.hover () =>
            @hover(link)
            link.click (e) =>
              @select(e, link)
          $("<li></li>").append(link).appendTo @container

        @suggestions = @container.find("a")
      else
        @hide()
      @options.afterSuggest.call @, suggestions  if @options.afterSuggest

    select: (e, selection) =>
      e.preventDefault()  if e
      selection ?= $(@suggestions.get(@suggestion))
      value = selection.text()
      if @options.fill_field
        @prompt.val value
      else @prompt.val ""  if @options.empty_field
      @form.submit()  if @options.submit_form
      @options.afterSelect.call @, value  if @options.afterSelect
      @hide()

    show: () =>
      unless @visible
        @container.fadeIn "slow"
        @visible = true

    hide: () =>
      if @visible
        @container.fadeOut "fast"
        @visible = false

    key: (e) =>
      key_code = e.which
      if @movement(key_code)
        @show()  if @suggestions.length > 0
        if @visible
          @movement(key_code).call @, e
          e.preventDefault()
          e.stopPropagation()
      else
        @get e

    movement: (key_code) =>
      switch key_code
        when 27 # escape
          @hide
        when 33 # page up
          @first
        when 38 # up
          @previous
        when 40 # down
          @next
        when 33 # page down
          @last
        when 9 # tab
          @next
        when 13 # enter
          @select

    next: (e) =>
      if @suggestion is null or @suggestion >= @suggestions.length - 1
        @first()
      else
        @highlight @suggestion + 1

    previous: (e) =>
      if @suggestion <= 0
        @last()
      else
        @highlight @suggestion - 1

    first: (e) =>
      @highlight 0

    last: (e) =>
      @highlight @suggestions.length - 1

    hover: (link) =>
      @highlight @suggestions.index(link) # this will be the hovered link

    highlight: (i) =>
      @unHighlight @suggestion  if @suggestion isnt null
      $(@suggestions.get(i)).addClass "hover"
      @suggestion = i

    unHighlight: (i) =>
      $(@suggestions.get(i)).removeClass "hover"
      @suggestion = null

    previously_blank: (query) =>
      if @blanks.length > 0
        blank_re = new RegExp("(" + @blanks.join("|") + ")")
        return blank_re.test(query)
      false


