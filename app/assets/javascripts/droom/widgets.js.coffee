# This is a collection of interface elements. They're all self-contained. Most are attached to a 
# form element and cause its value to change, but there are also some standalone widgets that live
# on the page and follow their own rules.

jQuery ($) ->

  $.fn.date_picker = ()->
    @each ->
      new DatePicker(@)

  class DatePicker
    @month_names: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    constructor: (element) ->
      @_container = $(element)
      if @_container.is("input")
        @_field = @_container
        event = 'focus'
      else
        @_field = @_container.find('input')
        event = 'click'
        @_mon = @_container.find('span.mon')
        @_dom = @_container.find('span.dom')
        @_year = @_container.find('span.year')
      initial_date = @getDate()
      @_container.DatePicker
        calendars: 1
        date: initial_date
        current: initial_date
        view: 'days'
        position: 'bottom'
        showOn: event
        onChange: @setDate

    getDate: () =>
      if value = @_field.val()
        new Date(Date.parse(value))

    setDate: (date) =>
      if date
        $('.datepicker').hide()
        d = $.zeroPad(date.getDate())
        m = DatePicker.month_names[date.getMonth()]
        y = date.getFullYear()
        dateString = [y, m, d].join('-')
        @_field.val(dateString)
        @_dom?.text(d)
        @_mon?.text(m)
        @_year?.text(y)


  class TimePicker
    constructor: (element) ->
      @field = $(element)
      @holder = $('<div class="timepicker" />')
      @dropdown = new Dropdown @field,
        on_select: @select
        on_keyup: @change
      times = []
      for i in [0..24]
        times.push({value: "#{i}:00"})
        times.push({value: "#{i}:30"})
      @dropdown.populate(times)
      @field.focus @show
      @field.blur @hide

    select: (value) =>
      @field.val(value)
      @field.trigger('change')

    change: (e) =>
      # this is called on keyup but only if the dropdown doesn't recognise the keypress as a command
      @dropdown.match(@field.val())

    show: (e) =>
      @dropdown.show()

    hide: (e) =>
      @dropdown.hide()

  $.fn.time_picker = ->
    @each ->
      new TimePicker(@)




  $.fn.file_picker = () ->
    @each ->
      new FilePicker @

  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()

  class FilePicker
    constructor: (element) ->
      @_container = $(element)
      @_form = @_container.parents('form')
      @_link = @_container.find('a[data-action="pick"]')
      @_filefield = @_container.find('input[type="file"]')
      @_file = null
      @_filename = ""
      @_ext = ""
      @_fields = @_container.siblings('.non-file-data')
      @_form.bind 'remote:upload', @initProgress
      @_form.bind 'remote:progress', @progress
      @_link.bind 'click', @picker
      @_filefield.bind 'change', @picked
    
    picker: (e) =>
      e.preventDefault() if e
      @_filefield.click()

    extensions: () =>
      @_extensions ?= ['doc', 'docx', 'pdf', 'xls', 'xlsx', 'jpg', 'png']

    picked: (e) =>
      @_link.removeClass(@extensions().join(' '))
      if files = @_filefield[0].files
        if @_file = files.item(0)
          @_previous_filename = @_filename ? ""
          @_filename = @_file.name.split(/[\/\\]/).pop()
          @_ext = @_filename.split('.').pop()
          @display()

    display: () =>
      @_link.addClass(@_ext) if @_ext in @extensions()
      @_form.find('input.name').val(@_filename) if $('input.name').val() is @_previous_filename

    initProgress: (e, xhr, settings) =>
      if @_file?
        @_fields.hide()
        @_notifier = $('<div class="notifier"></div>').appendTo @_form
        @_label = $('<h3 class="filename"></h3>').appendTo @_notifier
        @_progress = $('<div class="progress"></div>').appendTo @_notifier
        @_bar = $('<div class="bar"></div>').appendTo @_progress
        @_label.text(@_filename)
      true

    progress: (e, prog) =>
      if @_file? and prog.lengthComputable
        full_width = @_progress.width()
        progress_width = Math.round(full_width * prog.loaded / prog.total)
        @_bar.width progress_width

    remover: () =>
      unless @_remover?
        @_remover = $('<a href="#" class="remover" />').insertAfter(@_link)
        @_remover.click @remove
      @_remover

    remove: (e) =>
      e.preventDefault() if e
      old_ff = @_filefield
      @_filefield = old_ff.clone().insertAfter(old_ff)
      @_filefield.bind 'change', @picked
      old_ff.remove()
      @_form.find('input.name').val("") if $('input.name').val() is @_filename
      @_filename = ""
      @_ext = ""
      @_remover?.hide()
      @_link.css
        "background-image": @_original_background





  $.fn.droom_image_picker = () ->
    @each ->
      console.log "droom_image_picker", @
      new DroomImagePicker @

  class DroomImagePicker extends FilePicker
    display: () =>
      @_form.find('input.name').val(@_filename) if $('input.name').val() is @_previous_filename
      @_original_background ?= @_link.css("background-image")
      reader = new FileReader()
      reader.onload = (e) =>
        @_link.css
          "background-image": "url(#{reader.result})"
        @remover().show()
      reader.readAsDataURL(@_file)



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



  $.fn.password_fieldset = ->
    if @length
      new PasswordFieldset(@)


  class PasswordFieldset
    constructor: (element) ->
      @fieldset = $(element)
      @password_field = @fieldset.find('input[data-role="password"]')
      @confirmation_block = @fieldset.find('[data-role="confirmation"]')
      @confirmation_field = @confirmation_block.find('input')
      @confirmation_field.bind 'input', @checkConfirmation
      @submitter = @fieldset.parents('form').find('input[type="submit"]')
      meter_holder = @fieldset.find('[data-role="meter"]')
      if meter_holder.length
        @meter = new PasswordMeter(meter_holder)
      @password_field.bind 'input', @checkPassword
      @checkPassword()

    checkPassword: () =>
      # no password is ok, if password is not required
      if @empty()
        @unconfirmable()
        @password_field.removeClass('valid invalid')
        @meter?.clear()
        if @required()
          @unsubmittable()
        else
          @submittable()
        false

      # but if password is given, it must be long enough and strong enough
      else
        password = @password_field.val()
        ok = false
        if password.length < 6
          @meter?.tooShort()
        else
          @meter?.check(password)
          #TODO: agree and apply complexity requirements
          ok = true

        if ok
          @password_field.removeClass('invalid').addClass('valid')
          @confirmable()
        else
          @password_field.removeClass('valid').addClass('invalid')
          @unconfirmable()
        @checkConfirmation()
        ok

    # ... and confirmed.
    checkConfirmation: () =>
      if @confirmed()
        @confirmation_field.addClass('valid').removeClass('invalid')
        @submittable()
      else
        @confirmation_field.removeClass('valid').addClass('invalid')
        @unsubmittable() unless @empty() and not @required()

    required: () =>
      !!@password_field.attr('required')

    confirmed: () =>
      @confirmation_field.val() is @password_field.val()

    empty: () =>
      @password_field.val() == ""

    valid: () =>
      @confirmed() and (not @empty() or not @required())

    confirmable: () =>
      @confirmation_field.attr('required', true)
      @confirmation_block.enable()
      @unsubmittable()

    unconfirmable: () =>
      @confirmation_block.disable()
      @confirmation_field.attr('required', false)
      @unsubmittable()# if @required()

    submittable: () =>
      @submitter.enable()

    unsubmittable: () =>
      @submitter.disable()


  $.fn.password_meter = ->
    @each ->
      new PasswordMeter(@)
    @


  class PasswordMeter
    constructor: (element) ->
      @_container = $(element)
      @_warnings = @_container.find('[data-role="warnings"]')
      @_suggestions = @_container.find('[data-role="suggestions"]')
      @_gauge = @_container.find('[data-role="gauge"]')
      @_score = @_container.find('[data-role="score"]')
      @_notes = @_container.find('[data-role="notes"]')
      @_original_warning = @_warnings.html()
      @_original_notes = @_notes.html()
      @_zxcvbn_ready = false
      $.withZxcbvn =>
        @_ready = true

    clear: () =>
      @_warnings.text("")
      @_container.removeClass('s0 s1 s2 s3 s4 acceptable')
      @_notes.html(@_original_notes)
      @_warnings.html(@_original_warning)

    tooShort: () =>
      @clear()
      @_container.addClass('s0')
      @_warnings.text("Password too short.")

    check: (value) =>
      if @_ready
        result = zxcvbn(value)
        @display(result)
        result.score

    display: (result) =>
      if result.score < 2
        @_warnings.text(result.feedback.warning) if result.feedback?.warning
        @_suggestions.text(result.feedback?.suggestions)
        @_container.slideDown()
      else
        @_container.removeClass('s0 s1 s2 s3 s4 acceptable').slideUp()






  # The basic captive form is a fairly dumb binding between form element and target element.
  # The form is submitted over ajax and the response is displayed in the target.
  #
  # If options.fast is true then any change to an input or select within the form will trigger submission.
  # If options.auto is true then the form will be submitted immediately; more commonly the target is already
  # populated.
  #
  #todo: this really needs debouncing.
  #
  # There is some slack in the internal structure here because subclasses do more intermediate work.

  $.fn.captive = (options) ->
    @each ->
      new CaptiveForm @, options
    @

  # The filter form is a fast captive with only one input.
  # It ought to have a cache too, since there is a simple key.

  $.fn.filter_form = (options) ->
    @each ->
      new CaptiveForm @,
        fast: true
        into: "#found"
        auto: false
        history: false
    @

  $.fn.table_filter_form = (options) ->
    @each ->
      new CaptiveForm @,
        fast: true
        into: "table"
        auto: false
        history: true
    @

  $.fn.quick_search_form = (options) ->
    @each ->
      defaults = 
        fast: true
        into: "#found"
        auto: false
        history: false
      new CaptiveForm @, _.extend(defaults, options)
    @

  # The suggestions form is a fast filter form with history support
  #
  $.fn.suggestion_form = (options) ->
    @each ->
      new CaptiveForm @,
        fast: true
        auto: false
        into: "#suggestion_box"
        history: false
    @

  $.fn.faceting_search = (options) ->
    defaults = 
      fast: ".facet"
      history: true
      threshold: 4
    @each ->
      new CaptiveForm @, _.extend(defaults, options)
    @


  class CaptiveForm
    @default_options: {
      fast: false
      auto: false
      threshold: 3
      history: false
    }
    
    constructor: (element, opts) ->
      @_form = $(element)
      @_options = $.extend @constructor.default_options, opts
      @_historical = !!(Modernizr.history and @_options.history or @_form.attr('data-historical'))
      @_selector = @_form.attr('data-target') || @_options.into
      @_container = $(@_selector)
      @_original_qs = @serialize()
      @_original_content = @_container.html()
      @_request = null
      @_inactive = false
      @_cache = {}
      @_form.bind 'refresh', () =>
        @_form.submit()
      @_form.remote
        on_request: @prepare
        on_cancel: @cancel
        on_success: @capture
      @submit_soon = _.debounce(@submit, 500)
      @bindInputs(@_options.fast) if @_options.fast
      @_form.bind 'refresh', @changed
      if @_options.auto
        @submit()
      else
        @bindLinks()
      if @_historical
        @saveState(@_original_content)
        $(window).bind 'popstate', @restoreState
      $.qf = @

    bindLinks: () =>
      @_container.find('a.cancel').click(@revert)
      @_container.find('.pagination a').click @page

    bindInputs: (selector) =>
      if typeof selector is "string"
        @_form.find(selector).bind 'change', @changed
      else
        @_form.find('input[type="search"]').bind 'keyup', @changed
        @_form.find('input[type="search"]').bind 'change', @changed
        @_form.find('input[type="text"]').bind 'keyup', @keyed
        @_form.find('input[type="text"]').bind 'change', @changed
        @_form.find('select').bind 'change', @changed
        @_form.find('input[type="radio"]').bind 'click', @clicked
        @_form.find('input[type="checkbox"]').bind 'click', @clicked

    keyed: (e) =>
      k = e.which
      if k is 13
        @submit(e)
      if (k >= 46 and k <= 90) or (k >= 96 and k <= 111) or k is 8
        @changed(e)
    
    changed: (e) =>
      @submit_soon() unless @_inactive

    clicked: (e) =>
      @submit_soon() unless @_inactive

    serialize: () =>
      parameters = []
      @_form.find(":input").each (i, f) =>
        field = $(f)
        parameters.push field.serialize() unless field.val() is ""
      parameters.join('&')

    page: (e) =>
      e.preventDefault() if e
      a = $(e.target)
      href = a.attr('href')
      p = $.urlParam('page', href)
      @_form.find('input[name="page"]').val(p)
      @submit()

    submit: (e, nocache) =>
      e.preventDefault() if e
      nocache ?= false
      qs = @serialize()
      if !nocache and @_cache[qs]
        @display(@_cache[qs])
      else
        @_form.submit()

    prepare: (xhr, settings) =>
      @_container.fadeTo "fast", 0.2

    capture: (e, data, status, xhr) =>
      @_cache[@serialize()] = data
      @display(data)
      @saveState(data) if @_historical

    display: (results) =>
      replacement = $(results)
      @_container.empty().append(replacement).fadeTo("fast", 1)
      replacement.activate()
      replacement.find('a.cancel').click(@revert)
      @bindLinks()
      $("html, body").animate({ scrollTop: 0 }, "slow")

    revert: (e) =>
      @display(@_original_content)

    saveState: (results, qs) =>
      qs ?= @serialize()
      url = window.location.pathname + "?" + qs
      title = document.title + ' search'
      state = 
        html: results
        qs: qs
      history.pushState state, title, url

    restoreState: (e) =>
      event = e.originalEvent
      e.preventDefault() if e
      if event.state? && event.state.html?
        @display event.state.html
        @_inactive = true
        @_form.deserialize(event.state.qs)
        @_inactive = false










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
      # @_editor.on "load", () =>
      #   @_iframe = @_editor.composer.iframe
      #   $(@_editor.composer.doc).find('html').css
      #     "height": 0
      #   @resizeIframe()
      #   @_textarea = @_editor.composer.element
      #   @_textarea.addEventListener("keyup", @resizeIframe, false)
      #   @_textarea.addEventListener("blur", @resizeIframe, false)
      #   @_textarea.addEventListener("focus", @resizeIframe, false)
        
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
  # when its link is clicked.
      
  $.fn.folder = ->
    @each ->
      new Folder(@)

  class Folder
    constructor: (element) ->
      @_container = $(element)
      @_label = @_container.attr('data-label')
      @_list = @_container.children('ul.filing')
      if @_list[0]
        @_container.children('a.folder').click @toggle
        @set()
      else
        @_container.children('a.folder').remote
          on_success: @replace

    set: (e) =>
      e.preventDefault() if e
      @_state = localStorage?.getItem("show_folder_#{@_label}")
      @_state = "open" if @_container.hasClass('open')
      if @_state is "open"
        @_container.addClass("open")
        @_list.show()
      else
        @_container.removeClass("open")
        @_list.hide()

    replace: (e, response) =>
      replacement = $(response)
      @_container.after(replacement)
      @_container.remove()
      replacement.activate()

    toggle: (e) =>
      if e
        e.preventDefault() 
        e.stopPropagation()
      if @_container.hasClass('open') then @hide() else @show()

    show: (e) =>
      e.preventDefault() if e
      localStorage?.setItem("show_folder_#{@_label}", "open")
      @_container.addClass('open')
      @_list.stop().slideDown("fast")
      
    hide: (e) =>
      e.preventDefault() if e
      localStorage?.setItem("show_folder_#{@_label}", "closed")
      @_list.stop().slideUp "normal", () =>
        @_container.removeClass('open')




  $.fn.slug_field = ->
    @each ->
      new SlugField(@)
      
  class SlugField
    constructor: (element) ->
      @_field = $(element)
      @_form = @_field.parents('form')
      selector = @_field.attr('data-base') or 'input[data-role="name"]'
      @_base = @_form.find(selector)
      @_base.bind "keyup", @update
      @_previous_base = @_base.val()
      @set()
    
    update: (e) =>
      @set() if $.significantKeypress(e.which)
      
    set: () =>
      old_base = @_previous_base
      old_slug = @_field.val()
      new_base = @_base.val()
      # if no slug, or if slug looks like it was set automatically
      if old_slug is "" or old_slug is @slugify(old_base)
        @_field.val @slugify(new_base)
      @_previous_base = new_base

    slugify: (string) =>
      string.replace(/[^\w\d]+/g, '-').toLowerCase()


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

  # calendar_search links push their text into the suggestion box by way of the calendar.search function.
  # 
  $.fn.calendar_search = ->
    @click (e) ->
      e.preventDefault() if e
      $.calendar?.search($(@).text())




  class ScoreShower
    constructor: (element) ->
      @_container = $(element)
      @_rating = parseFloat(@_container.text(), 10)
      @_rating ||= 0
      @_bar = $('<div class="starbar" />').appendTo(@_container)
      @_mask = $('<div class="starmask" />').appendTo(@_container)
      @_bar.css
        width: @_rating / 5 * 80

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
      
    receive: (e, r) =>
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
    
    monthName: () =>
      months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
      months[@_month-1]
      
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
      width: 300
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
      @options = $.extend(
        fill_field: true
        empty_field: false
        submit_form: false
        preload: false
        width: "auto"
        threshold: 2
        limit: 10
        afterSuggest: null
        afterSelect: null
      , options)
      if options.type
        @options.url ?= "/suggestions/#{options.type}.json"
      else
        @options.url ?= "/suggestions.json"
      if @options.preload
        @options.url += "?empty=all"
      @dropdown = new Dropdown @prompt,
        on_select: @select
        on_keyup: @get
        width: @options.width
      @button = @form.find("a.search")
      @previously = null
      @request = null
      @visible = false
      @suggestions = []
      @suggestion = null
      @cache = {}
      @blanks = []
      @prompt.bind "blur", @hide
      @prompt.bind "paste", @get
      @form.submit @hide
      @get(null, true) if @options.preload
      @

    reset: () =>
      @dropdown.reset().hide()
      
    get: (e, force) =>
      @wait()
      query = @prompt.val()
      if force or query.length >= @options.threshold and query isnt @previously
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

    previously_blank: (query) =>
      if @blanks.length > 0
        blank_re = new RegExp("(" + @blanks.join("|") + ")")
        return blank_re.test(query)
      false
    
    suggest: (suggestions) =>
      @unwait()
      @dropdown.show(suggestions)
      @options.afterSuggest.call(@, suggestions) if @options.afterSuggest

    select: (value, id) =>
      if @options.fill_field?
        @prompt.val(value)
        @prompt.trigger('suggester.change')
      else if @options.empty_field?
        @prompt.val ""
      @options.afterSelect.call(@, value) if @options.afterSelect

    show: () =>
      @dropdown.show()

    hide: () =>
      @dropdown.hide()

    wait: () =>
      @button.addClass "waiting"
      @prompt.addClass "waiting"

    unwait: () =>
      @button.removeClass "waiting"
      @prompt.removeClass "waiting"
      






  $.fn.youtube_suggester = (options) ->
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
      @target = $('input#scrap_youtube_id')
      @name_field = $('input#scrap_name')
      @preview_holder = $('div.youtube_preview')
      @thumb_holder = @prompt.siblings('.thumbnail')

    suggest: (suggestions) =>
      @unwait()
      if suggestions.length > 0
        detailed_suggestions = $.map suggestions, (suggestion, i) ->
          {type: "video", id: suggestion.unique_id, value: "<img src='#{suggestion.thumbnails[0].url}' /><span class=\"title\">#{suggestion.title?.truncate(36)}</span><br /><span class=\"description\">#{suggestion.description?.truncate(48)}</span>"}
        @dropdown.show(detailed_suggestions)
      else
        @hide()
      @options.afterSuggest.call @, suggestions if @options.afterSuggest

    select: (value, id) =>
      @hide()
      @prompt.trigger 'suggester.change'
      @prompt.val(id)
      title = $("<div>#{value}</div>").find('.title')
      @name_field.val(title.text()) if @name_field.val() is ""
      @get_preview(id)
      @get_thumbnail(id)
      @options.afterSelect?.call(@, value)
    
    get_preview: (id) =>
      $.get "/videos/#{id}.js", @show_preview, 'html'
    
    show_preview: (response) =>
      @preview_holder.empty().show().html(response)

    get_thumbnail: (id) =>
      @thumb_holder.css
        "background-image": "url('http://img.youtube.com/vi/#{id}/3.jpg')"



  # I've just lifted this out of the suggester so that it can be used in other pickers.

  $.fn.dropdown = (options) ->
    @each ->
      new Dropdown(@, options)

  class Dropdown
    constructor: (element, opts) ->
      @hook = $(element)
      @drop = $('<ul class="dropdown" />').insertAfter(@hook).hide()
      @options = $.extend {}, opts
      @hook.bind "keydown", @keydown
      @hook.bind "keyup", @keyup
      @

    place: () =>
      unless width = @options.width
        width = @hook.outerWidth() - 2
      @drop.css
        top: @hook.position().top + @hook.outerHeight() - 2
        left: @hook.position().left
        width: width
      
    populate: (items) =>
      @reset()
      if items.length > 0
        $.each items, (i, item) =>
          id = item.id ? item.value ? item.unique_id
          value = item.title ? item.value ? item.prompt ? item.id
          link = $("<a href=\"#\">#{value}</a>")
          link.hover () =>
            @hover(link)
            link.click (e) =>
              e.preventDefault()
              e.stopPropagation()
              @item = i
              @select(value, id)
          $("<li></li>").addClass(item.type).append(link).appendTo(@drop)
      @items = @drop.find("a")
        
    reset: () =>
      @drop.empty()

    select_highlit: (e) =>
      if highlit = @items[@item]
        e.preventDefault()
        e.stopPropagation()
        @select $(highlit).text()

    select: (value, id) =>
      @hide()
      @options.on_select?(value, id)

    cancel: (e) =>
      @hide()
      @options.on_cancel?()
    
    show: (values) =>
      @place()
      @populate(values) if values
      unless @visible
        @drop.stop().fadeIn "fast"
        @visible = true
      
    hide: () =>
      if @visible
        @drop.stop().fadeOut "fast"
        @visible = false

    # the keyup and keydown handlers will first check for local significacne (ie it's a movement or action key 
    # that we recognise). If there is none, they call the supplied callback, if any. Event cancellation is up to
    # the called function: we don't stop propagation here.
    #
    # On keydown we look for keys that have to be intercepted: enter, mostly. Perhaps also tab, but that's not 
    # very reliable.
    #
    keydown: (e) =>
      kc = e.which
      if action = @actionKey(kc)
        action.call(@, e) if @items?.length
        return true
      else
        @options.on_keydown?(e)
        return true
        
    actionKey: (kc) =>
      switch kc
        # we may also want to catch tab here
        when 27 # escape
          @hide
        when 13 # enter
          @select_highlit

    # on keyup we look for movement keys. Everything else is let through.
    #
    keyup: (e, discard) =>
      kc = e.which
      if action = @movementKey(kc)
        @show() if @items?.length
        action.call(@, e) if @visible
        return true
      else
        @options.on_keyup?(e)
        return true

    movementKey: (kc) =>
      switch kc
        when 33 # page up
          @first
        when 38 # up
          @previous
        when 40 # down
          @next
        when 34 # page down
          @last

    match: (text) =>
      matching = @items.filter(":contains(#{text})")
      $.items = @items
      if item = matching.first()
        @hover(item)
        if holder = item.parents('li').first()
          top = holder.offset().top
          @drop.scrollTop(top)

    next: (e) =>
      if !@item? or @item >= @items.length - 1
        @first()
      else
        @highlight(@item + 1)

    previous: (e) =>
      if @item <= 0
        @last()
      else
        @highlight(@item - 1)

    first: (e) =>
      @highlight(0)

    last: (e) =>
      @highlight(@items.length - 1)

    hover: (link) =>
      @highlight(@items.index(link))

    highlight: (i) =>
      @unHighlight(@item) if @item isnt null
      $(@items.get(i)).addClass("hover")
      @item = i

    unHighlight: (i) =>
      if item = @items?.get(i)
        $(item).removeClass("hover")
      