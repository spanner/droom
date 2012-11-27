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

  $.fn.venue_picker = (options) ->
    options = $.extend(
      submit_form: true
      threshold: 1
      type: 'venue'
    , options)
    @each ->
      new Suggester(@, options)
    @

  $.fn.person_picker = (options) ->
    options = $.extend(
      submit_form: true
      threshold: 1
      type: 'person'
    , options)
    @each ->
      target = $(@).siblings('.person_picker_target')
      $(@).bind "keyup", () =>
        target.val null
      suggester = new Suggester(@, options)
      suggester.options.afterSelect = () ->
        id = JSON.parse(suggester.request.responseText)[0].id
        target.val id
        suggester.form.submit()
    @

  $.fn.group_picker = (options) ->
    options = $.extend(
      submit_form: true
      threshold: 1
      type: 'group'
    , options)
    @each ->
      target = $(@).siblings('.group_picker_target')
      $(@).bind "keyup", () =>
        target.val null
      suggester = new Suggester(@, options)
      suggester.options.afterSelect = () ->
        id = JSON.parse(suggester.request.responseText)[0].id
        target.val id
        suggester.form.submit()
    @

  $.fn.application_suggester = (options) ->
    options = $.extend(
      submit_form: false
      threshold: 1
      limit: 5
      type: 'application'
    , options)
    @each ->
      new Suggester(@, options)
    @

  class Suggester
    constructor: (element, options) ->
      @prompt = $(element)
      @type = @prompt.attr('data-type')
      @form = @prompt.parents("form")
      if options.type
        @url = "/suggestions/#{options.type}.json"
      else
        @url = "/suggestions.json"
      @options = $.extend(
        url: @url
        fill_field: true
        empty_field: false
        submit_form: false
        threshold: 2
        limit: 10
        afterSuggest: null
        afterSelect: null
      , options)
      @container = $("<ul class=\"suggestions\"></ul>").insertAfter(@prompt)
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
          @request = $.getJSON(@options.url, "term=" + encodeURIComponent(query) + "&limit=" + @options.limit, (suggestions) =>
            @cache[query] = suggestions
            @blanks.push query if suggestions.length is 0
            @suggest suggestions
          )
      else
        @hide()

    suggest: (suggestions) =>
      @button.removeClass "waiting"
      @show()
      if suggestions.length > 0
        $.each suggestions, (i, suggestion) =>
          link = $("<a href=\"#\">#{suggestion.prompt}</a>")
          value = suggestion.value || suggestion.prompt
          link.hover () =>
            @hover(link)
            link.click (e) =>
              @select(e, link, value)
          $("<li></li>").addClass(suggestion.type).append(link).appendTo @container

        @suggestions = @container.find("a")
      else
        @hide()
      @options.afterSuggest.call @, suggestions  if @options.afterSuggest

    select: (e, selection, value) =>
      e.preventDefault() if e
      selection ?= $(@suggestions.get(@suggestion))
      if @options.fill_field?
        @prompt.val value
        @prompt.trigger 'suggester.change'
      else if @options.empty_field?
        @prompt.val "" 
      if @options.submit_form?
        @form.submit()
      @options.afterSelect.call(@, value) if @options.afterSelect
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
        @show() if @suggestions.length > 0
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
