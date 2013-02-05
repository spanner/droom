# This is a collection of interface elements. 

jQuery ($) ->



  ## Form Widgets

  class DatePicker
    constructor: (element) ->
      @_container = $(element)
      @_trigger = @_container.find('a')
      @_field = @_container.find('input')
      @_holder = @_container.find('div.kal')
      @_mon = @_container.find('span.mon')
      @_dom = @_container.find('span.dom')
      @_year = @_container.find('span.year')
      @_kal = new Kalendae @_holder[0]
      @_holder.hide()
      @_trigger.click @toggle
      @_kal.subscribe 'change', () =>
        @hide()
        @_field.val(@_kal.getSelected())
        [year, month, day] = @_kal.getSelected().split('-')
        @_year.text(year)
        @_dom.text(day)
        @_mon.text(Kalendae.moment.monthsShort[parseInt(month, 10) - 1])

    toggle: (e) =>
      e.preventDefault() if e
      if @_holder.is(':visible') then @hide() else @show()

    show: () =>
      @_holder.fadeIn "fast", () =>
        @_container.addClass('editing')
        # $(document).bind "click", @hide
              
    hide: () =>
      # $(document).unbind "click", @hide
      @_container.removeClass('editing')
      @_holder.fadeOut("fast")

  $.fn.date_picker = () ->
    @each ->
      new DatePicker(@)
    @


  class TimePicker
    constructor: (element) ->
      holder = $('<div class="timepicker" />')
      menu = $('<ul />').appendTo(holder)
      field = $(element)
      for i in [0..24]
        $("<li>#{i}:00</li><li>#{i}:30</li>").appendTo(menu)
      menu.find('li').click (e) ->
        e.preventDefault()
        field.val $(@).text()
        field.trigger('change')
      field.after holder
      field.focus @show
      field.blur @hide
      @holder = holder
      @field = field

    show: (e) =>
      position = @field.position()
      @holder.css
        left: position.left
        top: position.top + @field.outerHeight() - 2
      @holder.show()
      $(document).bind "click", @hide
      
    hide: (e) =>
      unless e.target is @field[0]
        $(document).unbind "click", @hide
        @holder.hide()

  $.fn.time_picker = () ->
    @each ->
      new TimePicker(@)

  #todo: this can now make proper use of the remote mechanism and doesn't need to take over the whole form any more.
  #

  class FilePicker
    constructor: (element) ->
      @_container = $(element)
      @_form = @_container.parent()
      @_holder = @_form.parent()
      @_link = @_container.find('a.ul')
      @_filefield = @_container.find('input[type="file"]')
      @_tip = @_container.find('p.tip')
      @_link.click_proxy(@_filefield)
      @_extensions = ['doc', 'docx', 'pdf', 'xls', 'xlsx', 'jpg', 'png']
      @_filefield.bind 'change', @pick
      @_file = null
      @_filename = ""
      @_ext = ""
      @_fields = @_container.siblings('.metadata')
      @_form.submit @submit
      
    pick: (e) =>
      @_link.removeClass(@_extensions.join(' '))
      if files = @_filefield[0].files
        @_file = files.item(0)
        @_tip.hide()
        @showSelection() if @_file

    submit: (e) =>
      if @_file
        e.preventDefault() if e
        @_fields.hide()
        @_notifier = $('<div class="notifier"></div>').appendTo @_form
        @_label = $('<h3 class="filename"></h3>').appendTo @_notifier
        @_progress = $('<div class="progress"></div>').appendTo @_notifier
        @_bar = $('<div class="bar"></div>').appendTo @_progress
        @_status = $('<div class="status"></div>').appendTo @_notifier
        @_label.text(@_filename)
        @send()
      
    showSelection: () =>
      @_filename = @_file.name.split(/[\/\\]/).pop()
      @_ext = @_filename.split('.').pop()
      @_link.addClass(@_ext) if @_ext in @_extensions
      $('input.name').val(@_filename)# if $('input.name').val() is ""

    send: () =>
      formData = new FormData @_form.get(0)
      @xhr = new XMLHttpRequest()
      @xhr.onreadystatechange = @update
      @xhr.upload.onprogress = @progress
      @xhr.upload.onloadend = @finish
      url = @_form.attr('action')
      @xhr.open 'POST', url, true
      @xhr.send formData

    progress: (e) =>
      @_status.text("Uploading")
      if e.lengthComputable
        full_width = @_progress.width()
        progress_width = Math.round(full_width * e.loaded / e.total)
        @_bar.width progress_width
      
    update: () =>
      if @xhr.readyState == 4
        if @xhr.status == 200
          @_form.remove()
          @_holder.append(@xhr.responseText).delay(5000).slideUp()
          #todo: remove this nasty shortcut and integrate with RemoteForm and jquery_ujs
          #(which will require us to prevent form serialization in some way)
          $('.documents').trigger("refresh")
    
    finish: (e) =>
      @_status.text("Processing")
      @_bar.css
        "background-color": "green"



  $.fn.file_picker = () ->
    @each ->
      new FilePicker @

  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()




  class ScorePicker
    constructor: (element) ->
      @_field = $(element)
      @_container = $('<div class="starpicker" />')
      @_value = @_field.val()
      @_value = 
      for i in [1..5]
        do (i) =>
          star = $('<span class="star" />')
          star.attr('data-score', i)
          star.bind "mouseover", (e) =>
            @hover(e, star)
          star.bind "mouseout", (e) =>
            @unhover(e, star)
          star.bind "click", (e) =>
            @set(e, star)
          @_container.append star
      @_stars = @_container.find('span.star')
      @_field.after(@_container)
      @_field.hide()

    hover: (e, star) =>
      @unhover()
      i = parseInt(star.attr('data-score'))
      @_stars.slice(0, i).addClass('hovered')
    
    unhover: (e, star) =>
      @_stars.removeClass('hovered')

    set: (e, star) =>
      e.preventDefault if e
      @unhover()
      i = parseInt(star.attr('data-score'))
      @_stars.removeClass('selected')
      @_stars.slice(0, i).addClass('selected')
      @_field.val(i)


  $.fn.score_picker = () ->
    @each ->
      new ScorePicker @
    

  class ScoreShower
    constructor: (element) ->
      @_container = $(element)
      @_rating = parseFloat(@_container.text(), 10)
      @_rating ||= 0
      @_bar = $('<div class="starbar" />').appendTo(@_container)
      @_mask = $('<div class="starmask" />').appendTo(@_container)
      @_bar.css
        width: @_rating/5 * 80

  $.fn.star_rating = () ->
    @each ->
      new ScoreShower @


  class PasswordField
    constructor: (element, opts) ->
      @options = $.extend
        length: 6
      , opts
      @field = $(element)
      @_notice = $('.notice')
      @form = @field.parents('form')
      @submit = @form.find('.submit')
      @confirmation = $("#" + @field.attr("id") + "_confirmation")
      @confirmation_holder = @confirmation.parents("p")
      @mock_password = 'password'
      @required = @field.attr('required')
      @field.focus @wake
      @field.blur @sleep
      @field.keyup @check
      @confirmation.keyup @check
      @form.submit @stumbit
      # to set up initial state
      @check()
      @sleep()

    wake: () =>
      if @field.val() is @mock_password
        @field.removeClass "empty"
        @field.val ""

    sleep: () =>
      v = @field.val()
      if v is @mock_password or v is ""
        @field.val @mock_password
        @field.addClass("empty")
        # if we're not required, then both-empty is also a submittable condition
        if @confirmation.val() is "" and not @required
          @submittable()

    check: () =>
      if @empty() and !@required
        @field.removeClass("ok notok").addClass("empty")
        @confirmation_holder.hide()
        @submittable()
        @notify ""
      else if @valid()
        @field.addClass("ok").removeClass "notok"
        @confirmation_holder.show()
        @notify "You must confirm your password before you can proceed."
        if @matching()
          @notify "Passwords match.", "successful"
          @confirmation.addClass("ok").removeClass("notok")
          @submittable()
        else
          @notify "The confirmation does not match your password.", "erratic"
          @confirmation.addClass("notok").removeClass("ok")
          @unsubmittable()
      else
        @confirmation_holder.hide()
        @confirmation.val ""
        @unsubmittable()
        @field.addClass("notok").removeClass("ok")
        @confirmation.addClass("notok").removeClass("ok")
        @notify "Please enter password of at least six letters.", "erratic"
    
    notify: (message, cssclass) =>
      @_notice.removeClass('erratic successful').addClass(cssclass).text(message)
      
    submittable: () =>
      @submit.removeClass("unavailable")
      @blocked = false

    unsubmittable: () =>
      @submit.addClass("unavailable")
      @blocked = true

    empty: () =>
      !@field.val() || @field.val().length == 0
      
    valid: () =>
      v = @field.val()
      v.length >= @options.length and (!@options.validator? or @options.validator.test(v))

    matching: () =>
      @confirmation.val() is @field.val()

    stumbit: (e) =>
      if @blocked
        e.preventDefault()
      else
        @field.val("") if @field.val() is @mock_password
        

  $.fn.password_field = ->
    @each ->
      new PasswordField(@)


  # The Calendar widget is a display of one calendar month in the usual tabular format.
  # Here we wrap it in a scrolling div to support movement from one month to another and
  # hook it up to the suggestion box, if that's on the page, so that clicking a day or month
  # name will populate the box (and so trigger a search for events in that period).
  #
  # For now we're saving some hassle by assuming that there is only one calendar and saving it
  # in $.calendar for manipulating links to refer to.

  $.fn.calendar = ->
    @each ->
      new Calendar(@)
    @
    
  # The calendar changer action usually belongs only to the next and previous buttons that sit in the 
  # calendar table, but you can also put links on the page to specific months.
  #
  $.fn.calendar_changer = ->
    @click (e) ->
      e.preventDefault() if e
      link = $(@)
      year = parseInt(link.attr('data-year'), 10)
      month = parseInt(link.attr('data-month'), 10)
      link.addClass('waiting')
      $.calendar?.show(year, month)
    @

  # calendar_search links push their text into the suggestion box by way of the calendar.searchFor function.
  # 
  $.fn.calendar_search = ->
    @click (e) ->
      e.preventDefault() if e
      $.calendar?.searchFor($(@).text())

  class Calendar
    constructor: (element, options) ->
      @_container = $(element)
      @_scroller = @_container.find('.scroller')
      @_table = null
      @_cache = {}
      @_month = null
      @_year = null
      @_request = null
      @_incoming = {}
      @_width = @_container.width()
      $.calendar = @
      @_container.bind "refresh", @refresh_in_place
      @init()

    init: () =>
      @_table = @_container.find('table')
      @_month = parseInt(@_table.attr('data-month'), 10)
      @_year = parseInt(@_table.attr('data-year'), 10)
      @cache(@_year, @_month, @_table)
      @_table.find('a.next, a.previous').calendar_changer()
      @_table.find('a.day').day_search()
      @_table.find('a.month').month_search()
      
    cache: (year, month, table) =>
      @_cache[year] ?= {}
      @_cache[year][month] ?= table
    
    cached:  (year, month) =>
      @_cache[year] ?= {}
      @_cache[year][month]
    
    # The calendar is intrinsically refreshable: it responds to a 'refresh' event by calling this method 
    # to reload the currently displayed month/year.
    #
    refresh_in_place: () =>
      @_request = $.ajax
        type: "GET"
        dataType: "html"
        url: "/events/calendar.js?month=#{encodeURIComponent(@_month)}&year=#{encodeURIComponent(@_year)}"
        success: @update_quietly
      
    update_quietly: (response) =>
      @_container.find('a').removeClass('waiting')
      @_scroller.find('table').remove()
      @_scroller.append(response)
      @init()
      
    show: (year, month) =>
      if cached = @cached(year, month)
        @update(cached, year, month)
      else
        @_request = $.ajax
          type: "GET"
          dataType: "html"
          url: "/events/calendar.js?month=#{encodeURIComponent(month)}&year=#{encodeURIComponent(year)}"
          success: (response) =>
            @update(response, year, month)
    
    update: (response, year, month) =>
      @_container.find('a').removeClass('waiting')
      direction = "left" if ((year * 12) + month) > ((@_year * 12) + @_month)
      @sweep response, direction
    
    sweep: (table, direction) =>
      old = @_scroller.find('table')
      if direction == 'left'
        @_scroller.append(table)
        @_container.animate {scrollLeft: @_width}, 'fast', () =>
          old.remove()
          @_container.scrollLeft(0)
          @init()
      else
        @_scroller.prepend(table)
        @_container.scrollLeft(@_width).animate {scrollLeft: 0}, 'fast', () =>
          old.remove()
          @init()
    
    # This use of moment depends on the loading of Kalendae, which we use for the date-picker widget above.
    #
    monthName: () =>
      Kalendae.moment.months[@_month-1]
      
    searchForm: =>
      @_form ?= $('#searchform')
      
    searchFor: (day) =>
      if day?
        @search("#{@monthName()} #{day}, #{@_year}")
      else
        @search("#{@monthName()} #{@_year}")

    search: (term) =>
      @searchForm().find('input#term').val(term)
      @searchForm().submit()
      


  # The Suggester hooks us up to the same machinery as drives the main suggestions box, usually with some
  # restrictions to eg. a single type of object. It lets us provide typeahead boxes that work both for existing
  # and new objects.
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
      
      @prompt.keyup @keyed
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

    keyed: (e) =>
      key_code = e.which
      if action = @movementKey(key_code)
        @show() if @suggestions.length > 0
        if @visible
          action.call @, e
          e.preventDefault()
          e.stopPropagation()
      else if @inputKey(key_code)
        @get e

    movementKey: (kc) =>
      switch kc
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

    inputKey: (kc) =>
      #delete,     backspace,    alphanumerics,    number pad,        punctuation
      (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
      
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



