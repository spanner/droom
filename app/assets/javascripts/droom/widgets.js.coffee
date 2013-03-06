# This is a collection of interface elements. They're all self-contained. Most are attached to a 
# form element and cause its value to change, but there are also some standalone widgets that live
# on the page and follow their own rules.

jQuery ($) ->

  ## Form Widgets
  #
  # These attach to a form element and provide a nicer interface by which to update its content.

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

  $.fn.time_picker = ->
    @each ->
      new TimePicker(@)

  #todo: this can now make proper use of the remote mechanism and doesn't need to take over the whole form any more.
  #

  class FilePicker
    constructor: (element) ->
      @_container = $(element)
      @_form = if form = @_container.attr("data-form") then $(form) else @_container.parent()
      @_holder = @_form.parent()
      @_link = @_container.find('a.ul')
      @_filefield = @_container.find('input[type="file"]')
      @_tip = @_container.find('p.tip')
      @_link.click_proxy(@_filefield)
      @_extensions = ['doc', 'docx', 'pdf', 'xls', 'xlsx', 'jpg', 'png']
      @_filefield.bind 'change', @pick
      @_file = null
      @_form.bind "finished", (e) =>
        console.log "filepicker has triggered 'finished'", e
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
      unless @_filefield.attr("disabled")
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

    showSelection: =>
      @_filename = @_file.name.split(/[\/\\]/).pop()
      @_ext = @_filename.split('.').pop()
      @_link.addClass(@_ext) if @_ext in @_extensions
      $('input.name').val(@_filename)# if $('input.name').val() is ""

    send: =>
      formData = new FormData @_form.get(0)
      @xhr = new XMLHttpRequest()
      @xhr.onreadystatechange = @update
      @xhr.upload.onprogress = @progress
      @xhr.upload.onloadend = @finish
      url = @_form.attr('action')
      @xhr.open 'POST', url, true
      @xhr.send formData

    progress: (e) =>
      @_status.text("Uploading. Please wait.")
      if e.lengthComputable
        full_width = @_progress.width()
        progress_width = Math.round(full_width * e.loaded / e.total)
        @_bar.width progress_width

    update: =>
      if @xhr.readyState == 4
        if @xhr.status == 200
          response = @xhr.responseText
          @_form.remove()
          @_holder.append(response)
          console.log "triggering 'finished' on", @_holder
          @_holder.trigger "finished", response

    finish: (e) =>
      @_status.text("Indexing for search. Please wait.")
      @_bar.css
        "background-color": "green"



  $.fn.file_picker = () ->
    @each ->
      new FilePicker @

  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()




  $.fn.score_picker = () ->
    @each ->
      new ScorePicker @

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


  $.fn.password_field = ->
    @each ->
      new PasswordField(@)

  class PasswordField
    constructor: (element, opts) ->
      @options = $.extend
        length: 6
      , opts
      @field = $(element)
      @_notice = $('.password_notice')
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
          if @confirmation_empty()
            @notify "Please confirm your password."
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
        if @empty()
          @notify "Please enter a password."
        else
          @notify "Your password should have least six letters.", "erratic"
    
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

    confirmation_empty: () =>
      !@confirmation.val() || @confirmation.val().length == 0
      
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
        


  # A captive form submits via an ajax request and pushes its results into the present page in the place 
  # designated by its 'replacing' attribute.
  #
  # If options['fast'] is true, the form will submit on every change to a text, radio or checkbox input.
  #
  #todo: This is very old now. Tidy it up with a more standard action structure, and fewer options.

  $.fn.captive = (options) ->
    @each ->
      new CaptiveForm @, options
    @

  class CaptiveForm
    constructor: (element, opts) ->
      @_form = $(element)
      @_options = $.extend {
        fast: false
        auto: false
        historical: false
      }, opts
      @_selector = @_form.attr('data-target') || @_options.into
      @_container = $(@_selector)
      @_original_content = @_container.html()
      @_prompt = @_form.find("input[type=\"text\"]")
      @_request = null
      @_form.remote
        on_submit: @prepare
        on_cancel: @cancel
        on_success: @capture
      if @_options.fast
        @_form.find("input[type=\"text\"]").keyup @keyed
        @_form.find("input[type=\"text\"]").change @submit
        @_form.find("input[type=\"radio\"]").click @clicked
        @_form.find("input[type=\"checkbox\"]").click @clicked
      @submit() if @_options.auto
        
    keyed: (e) =>
      k = e.which
      if (k >= 32 and k <= 165) or k == 8
        if @_prompt.val() is "" and not @_options.auto
          @revert()
        else
          @submit()
          
    clicked: (e) =>
      @submit()
      
    submit: (e) =>
      @_form.submit()
      
    prepare: (xhr, settings) =>
      @_container.fadeTo "fast", 0.2
      @_request.abort() if @_request
      @_request = xhr
    
    capture: (data, status, xhr) =>
      @display(data)
      @_request = null
    
    display: (results) =>
      replacement = $(results)
      @_container.empty().append(replacement).fadeTo("fast", 1)
      replacement.activate()
      replacement.find('a.cancel').click(@revert)
        
    revert: (e) =>
      console.log "revert"
      e.preventDefault() if e
      @display(@_original_content)
      @_prompt.val("")
      @saveState()


  $.fn.filter_form = (options) ->
    options = $.extend(
      fast: true
      auto: true
      into: "#found"
    , options)
    @each ->
      new CaptiveForm @, options
    @



  # The suggestions form is a fast captive with history support based on a single prompt field.
  #
  $.fn.suggestion_form = (options) ->
    options = $.extend(
      fast: true
      auto: false
      into: "#suggestion_box"
    , options)
    @each ->
      new SuggestionForm @, options
    @
  
  class SuggestionForm extends CaptiveForm
    constructor: (element, opts) ->
      super
      @_prompt = @_form.find("input[type=\"text\"]")
      @_param = @_prompt.attr('name')
      @_original_term = decodeURIComponent($.urlParam(@_param))
      if @_original_term and @_original_term isnt "false" and @_original_term isnt ""
        @_prompt.val(@_original_term)
        @submit()
      if Modernizr.history
        $(window).bind 'popstate', @restoreState

    capture: (data, status, xhr) =>
      @saveState(data) if Modernizr.history
      super

    saveState: (results) =>
      results ?= @_original_content
      term = @_prompt.val()
      if term
        url = window.location.pathname + "?" + encodeURIComponent(@_param) + "=" + encodeURIComponent(term)
      else
        url = window.location.pathname
      state = 
        html: results
        term: term
      history.pushState state, "Search results", url
    
    restoreState: (e) =>
      event = e.originalEvent
      if event.state? && event.state.html?
        @display event.state.html
        @_prompt.val(event.state.term)


  # The preferences form is a simple captive that just displays a confirmation message, with or without some control
  # links (eg to copy or delete dropboxed folders). It may also include a number of preference blocks, which take care
  # of showing and hiding subsidiary options.

  $.fn.preferences_form = (options) ->
    options = $.extend(
      fast: true
      clearing: null
      replacing: ".confirmation"
    , options)
    @each ->
      $(@).find('span.preference').preferences_block()
      new CaptiveForm @, options

  # The preferences block is a very minimal subcontent toggle. If the first contained radio or checkbox element
  # is checked, anything `.subpreference` is revealed. If its state changes, we show or hide.
  #
  # Note that to make this work with radio buttons we have applied a small hack to make sure they fire a change event
  # on deselection. See $.trigger_change_on_deselect in utilities.js.

  $.fn.preferences_block = ->
    @each ->
      new PreferenceBlock(@)

  class PreferenceBlock
    constructor: (element) ->
      @_container = $(element)
      @_input = @_container.find("> input")
      @_subprefs = @_container.find('span.subpreference')
      if @_subprefs.length
        @_input.trigger_change_on_deselect()
        @_input.change @set
        @set()
        
    set: (e) =>
      # let the event through...
      if @_input.is(":checked") then @show() else @hide()
    show: () =>
      @_subprefs.slideDown()
    hide: () =>
       @_subprefs.slideUp()


  # HTML-editing support is provided by WysiHTML, which is an ugly but effective iframe-based solution.
  # Any textarea with the 'data-editable' attribute will be handed over to WysiHTML for processing.
  #
  #todo: make this true
  #
  $.fn.html_editable = ()->
    @each ->
      new Editor(@)

  class Editor
    constructor: (element) ->
      @_container = $(element)
      @_textarea = @_container.find('textarea')
      @_toolbar = @_container.find('.toolbar')
      @_toolbar.attr('id', $.makeGuid()) unless @_toolbar.attr('id')?
      @_textarea.attr('id', $.makeGuid()) unless @_textarea.attr('id')?
      stylesheets = $("link").map ->
        $(@).attr('href')
      @_editor = new wysihtml5.Editor @_textarea.get(0),
        stylesheets: stylesheets,
        toolbar: @_toolbar.get(0),
        parserRules: wysihtml5ParserRules
        useLineBreaks: false
      @_toolbar.show()
      @_editor.on "load", () =>
        @_iframe = @_editor.composer.iframe
        $(@_editor.composer.doc).find('html').css
          "height": 0
        @resizeIframe()
        @_textarea = @_editor.composer.element
        @_textarea.addEventListener("keyup", @resizeIframe, false)
        @_textarea.addEventListener("blur", @resizeIframe, false)
        @_textarea.addEventListener("focus", @resizeIframe, false)
        
    resizeIframe: () =>
      if $(@_iframe).height() != $(@_editor.composer.doc).height()
        $(@_iframe).height(@_editor.composer.element.offsetHeight)
    
    showToolbar: () =>
      @_hovered = true
      @_toolbar.fadeTo(200, 1)

    hideToolbar: () =>
      @_hovered = false
      @_toolbar.fadeTo(1000, 0.2)






  ## Display Widgets
  #
  # These stand alone and usually encapsulate some interaction with the user.

  # The *folder* action is just a display convention that shows and hides the contents of a folder
  # when its link is clicked. It could perhaps become a subclass of the generic toggle mechanism and benefit from its persistence.
      
  $.fn.folder = ->
    @each ->
      new Folder(@)
      
  class Folder
    constructor: (element) ->
      @_container = $(element)
      @_list = @_container.children('ul.filing')
      @_container.children('a.folder').click @toggle
      @set()
      
    set: (e) =>
      e.preventDefault() if e
      if @_container.hasClass('open') then @show() else @hide()

    toggle: (e) =>
      if e
        e.preventDefault() 
        e.stopPropagation()
      if @_container.hasClass('open') then @hide() else @show()

    show: (e) =>
      e.preventDefault() if e
      @_container.addClass('open')
      @_list.stop().slideDown("fast")
      
    hide: (e) =>
      e.preventDefault() if e
      @_list.stop().slideUp "normal", () =>
        @_container.removeClass('open')


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


  # The page turner is a pagination link that retrieves a page of results remotely
  # then slides it into view from either the right or left depending on its relation 
  # to the current page.

  $.fn.sliding_link = () ->
    @each ->
      new Slider(@)
  
  class Slider
    constructor: (element) ->
      @_link = $(element)
      @_selector = @_link.attr('data-affected') || @defaultSelector()
      @_direction = @getDirection()
      @_page = @getPage()
      
      # build viewport and sliding frame around the the content-holding @_page
      @_frame = @_page.parents('.scroller').first()
      unless @_frame.length
        @_page.wrap($('<div class="scroller" />'))
        @_frame = @_page.parent()

      @_viewport = @_frame.parents('.scrolled').first()
      unless @_viewport.length
        @_frame.wrap($('<div class="scrolled" />'))
        @_viewport = @_frame.parents('.scrolled')

      @_width = @_page.width()
      @_link.remote
        on_success: @receive
      
    getPage: =>
      @_link.parents(@_selector).first()
      
    getDirection: =>
      @_link.attr "data-direction"

    defaultSelector: () =>
      '.scrap'
      
    receive: (r) =>
      response = $(r)
      @sweep response
      response.activate()
      
    sweep: (r) =>
      @_old_page = @_page
      @_viewport.css("overflow", "hidden")
      if @_direction == 'right'
        @_frame.append(r)
        @_viewport.animate {scrollLeft: @_width}, 'slow', 'glide', @cleanup
      else
        @_frame.prepend(r)
        @_viewport.scrollLeft(@_width).animate {scrollLeft: 0}, 'slow', 'glide', @cleanup
          
    cleanup: () =>
      @_viewport.scrollLeft(0)
      @_old_page.remove()



  $.fn.page_turner = () ->
    @each ->
      new Pager(@)

  class Pager extends Slider
    constructor: (element) ->
      super
      @_page_number = parseInt(@_link.parent().siblings('.current').text())
    
    defaultSelector: () =>
      '.paginated'
      
    getDirection: =>
      if @_link.attr "rel"
        @_direction = if @_link.attr("rel") == "next" then "right" else "left"
      else
        @_direction = if parseInt(@_link.text()) > @_page_number then "right" else "left"






  #todo: make this a case of the page turner?

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
      @_table.find('a.day').click @searchForDay
      @_table.find('a.month').click @searchForMonth
      
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
      @_form ?= $('#suggestions')
    
    searchForDay: (e) =>
      e.preventDefault() if e
      day = $(e.target).text()
      @search("#{day} #{@monthName()} #{@_year}")

    searchForMonth: (e) =>
      e.preventDefault() if e
      @search("#{@monthName()} #{@_year}")
      
    search: (term) =>
      @searchForm()?.find('input#term').val(term).change()
      @searchForm().trigger('show')
      # should trigger a change event, then we hit the cache if possible
      # @searchForm()?.submit()
      


  # The Suggester hooks us up to the machinery that drives the main suggestions box, usually with some
  # restrictions to eg. a single type of object. It lets us provide typeahead boxes that work both for existing
  # and new objects.
  #
  # The suggestion box itself is just `suggestible`. Other inputs are generally more restricted.
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
      submit_form: false
      threshold: 1
      type: 'venue'
    , options)
    @each ->
      new Suggester(@, options)
    @

  $.fn.person_selector = (options) ->
    options = $.extend(
      submit_form: false
      threshold: 1
      type: 'person'
    , options)
    @each ->
      target = $(@).siblings('.person_picker_target')
      $(@).bind "keyup", () =>
        target.val null
      suggester = new Suggester(@, options)
      suggester.options.afterSelect = (value, id) ->
        target.val id
    @

  $.fn.person_picker = (options) ->
    options = $.extend(
      submit_form: false
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

  $.fn.group_selector = (options) ->
    options = $.extend(
      submit_form: false
      threshold: 1
      type: 'group'
    , options)
    @each ->
      target = $(@).siblings('.group_picker_target')
      $(@).bind "keyup", () =>
        target.val null
      suggester = new Suggester(@, options)
      suggester.options.afterSelect = (value, id) ->
        target.val id
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
      @prompt.bind "paste", @get
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
      @prompt.addClass "waiting"
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
          @request.abort() if @request
          @request = $.getJSON(@options.url, "term=" + encodeURIComponent(query) + "&limit=" + @options.limit, (suggestions) =>
            @cache[query] = suggestions
            @blanks.push query if suggestions.length is 0
            @suggest suggestions
          )
      else
        @hide()

    suggest: (suggestions) =>
      @button.removeClass "waiting"
      @prompt.removeClass "waiting"
      @show()
      console.log "suggestions.length =>", suggestions.length
      if suggestions.length > 0
        $.each suggestions, (i, suggestion) =>
          link = $("<a href=\"#\">#{suggestion.prompt}</a>")
          id = suggestion.id
          value = suggestion.value || suggestion.prompt
          console.log 
          link.hover () =>
            @hover(link)
            link.click (e) =>
              @select(e, link, value, id)
          $("<li></li>").addClass(suggestion.type).append(link).appendTo @container

        @suggestions = @container.find("a")
      else
        @hide()
      @options.afterSuggest.call @, suggestions  if @options.afterSuggest

    select: (e, selection, value, id) =>
      e.preventDefault() if e
      selection ?= $(@suggestions.get(@suggestion))
      if @options.fill_field?
        @prompt.val value
        @prompt.trigger 'suggester.change'
      else if @options.empty_field?
        @prompt.val "" 
      # if @options.submit_form?
      #   @form.submit()
      @options.afterSelect.call(@, value, id) if @options.afterSelect
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




  $.fn.video_picker = (options) ->
    options = $.extend(
      submit_form: true
      threshold: 3
      type: "video"
      url: "/videos.json"
    , options)
    @each ->
      new YoutubeSuggester(@, options)
    @


  class YoutubeSuggester extends Suggester
    constructor: () ->
      super
      @target = $('textarea#scrap_body')
      @thumb = $('.scrapvideo .thumb')

    suggest: (suggestions) =>
      @button.removeClass "waiting"
      @prompt.removeClass "waiting"
      console.log "yt suggest", suggestions
      if suggestions.length > 0
        $.each suggestions, (i, suggestion) =>
          link = $("<a href=\"/videos/#{suggestion.unique_id}.js\"><img src='#{suggestion.thumbnails[2].url}' /><span class=\"title\">#{suggestion.title.truncate(36)}</span><br /><span class=\"description\">#{suggestion.description.truncate(48)}</span></a>")
          value = suggestion.value || suggestion.prompt
          link.remote
            on_success: (response) =>
              @select(response, suggestion)
          link.hover () =>
            @hover(link)
          $("<li></li>").addClass("video").append(link).appendTo(@container)
        @suggestions = @container.find("a")
        @show()
      else
        @hide()
      @options.afterSuggest.call @, suggestions  if @options.afterSuggest

    select: (response, selection) =>
      @hide()
      @prompt.trigger 'suggester.change'
      @target.val selection.unique_id
      @thumb.empty().html(response)
      @options.afterSelect?.call(@, value)
    


