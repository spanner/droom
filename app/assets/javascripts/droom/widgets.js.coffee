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
      @_container.click @contain
      @_kal.subscribe 'change', () =>
        @hide()
        @_field.val(@_kal.getSelected())
        [year, month, day] = @_kal.getSelected().split('-')
        @_year.text(year)
        @_dom.text(day)
        @_mon.text(Kalendae.moment.monthsShort[parseInt(month, 10) - 1])

    contain: (e) =>
      e.stopPropagation() if e

    toggle: (e) =>
      e.preventDefault() if e
      if @_holder.is(':visible') then @hide() else @show()

    show: () =>
      @_holder.fadeIn "fast", () =>
        @_container.addClass('editing')
        $(document).bind "click", @hide
              
    hide: () =>
      $(document).unbind "click", @hide
      @_container.removeClass('editing')
      @_holder.fadeOut("fast")

  $.fn.date_picker = () ->
    @each ->
      new DatePicker(@)
    @


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





  $.fn.image_picker = () ->
    @each ->
      new ImagePicker @

  class ImagePicker extends FilePicker
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






  $.fn.password_form = ->
    @each ->
      new PasswordForm(@)

  class PasswordForm
    constructor: (element, opts) ->
      @options = $.extend
        length: 6
      , opts
      @form = $(element)
      @password_field = @form.find('input.password')
      @confirmation_field = @form.find('input.password_confirmation')
      @fields = @form.find('input')
      @confirmation_holder = @confirmation_field.parents("p")
      @submit = @form.find('.submit')
      @required = @password_field.attr('required')

      @fields.bind 'keyup', @checkForm
      @password_field.bind 'keyup', @checkPassword
      @fields.bind 'invalid', @invalidField
      @form.bind 'submit', @submitIfValid
      
      @fields.attr('data-strict', false)
      @unsubmittable()
      @confirmation_holder.hide()

    checkForm: () =>
      @fields.removeClass('invalid').addClass('valid')
      if @form.get(0).checkValidity() then @submittable() else @unsubmittable()
    
    invalidField: () ->
      # note thin arrow: `this` is the failing input element
      field = $(@)
      field.removeClass('valid')
      if !field.attr('data-strict') and !field.val() or field.val() is ""
        field.addClass('empty')
      else
        field.addClass("invalid")
      
    checkPassword: () =>
      if @password_field.val() == "" and !@required
        @confirmation_field.attr('pattern', '').attr('required', false)
        @confirmation_holder.hide()
      else
        @confirmation_field.attr('pattern', @password_field.val()).attr('required', true)
        if @password_field.get(0).checkValidity()
          @confirmation_holder.show()
        else
          @confirmation_holder.hide()
          
    submittable: () =>
      @submit.removeClass("unavailable")
      @blocked = false

    unsubmittable: () =>
      @submit.addClass("unavailable")
      @blocked = true

    submitIfValid: (e) =>
      @fields.attr('data-strict', true)
      @checkForm()
      if @blocked
        e.preventDefault()
      else
        # might as well debounce, since we're here
        @submit.val('please wait')
        @unsubmittable()






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

  class CaptiveForm
    @default_options: {
      fast: false
      auto: false
      threshold: 3
    }
    
    constructor: (element, opts) ->
      @_form = $(element)
      @_options = $.extend @constructor.default_options, opts
      @_selector = @_form.attr('data-target') || @_options.into
      @_container = $(@_selector)
      @_original_content = @_container.html()
      @_request = null
      @_form.remote
        on_request: @prepare
        on_cancel: @cancel
        on_success: @capture
      @bindInputs() if @_options.fast
      @submit() if @_options.auto

    bindInputs: () =>
      @_form.find('input[type="search"]').bind 'keyup', @changed
      @_form.find('input[type="search"]').bind 'change', @changed
      @_form.find('input[type="search"]').bind 'click', @changed  # for the clear-box control in webkit search fields
      @_form.find('input[type="text"]').bind 'keyup', @keyed
      @_form.find('input[type="text"]').bind 'change', @changed
      @_form.find('select').bind 'change', @changed
      @_form.find('input[type="radio"]').bind 'click', @clicked
      @_form.find('input[type="checkbox"]').bind 'click', @clicked

    keyed: (e) =>
      k = e.which
      if (k >= 32 and k <= 165) or k == 8
        @changed()
    
    changed: () =>
      @submit()
          
    clicked: (e) =>
      @submit()
      
    submit: (e) =>
      @_form.submit()
      
    prepare: (xhr, settings) =>
      @_container.fadeTo "fast", 0.2
      @_request.abort() if @_request
      @_request = xhr
    
    capture: (e, data, status, xhr) =>
      @display(data)
      @_request = null
    
    display: (results) =>
      replacement = $(results)
      @_container.empty().append(replacement).fadeTo("fast", 1)
      replacement.activate()
      replacement.find('a.cancel').click(@revert)




  # The filter form is a fast captive with only one input.
  # It ought to have a cache too, since there is a simple key.

  $.fn.filter_form = (options) ->
    @each ->
      new FilterForm @, options
    @

  class FilterForm extends CaptiveForm
    @default_options: {
      fast: true
      into: "#found"
      auto: false
    }

    prompt: () =>
      @_prompt ?= @_form.find('input[type="search"], input[type="text"]').first()

    value: () =>
      @prompt().val()

    changed: () =>
      if @value() is "" and not @_options.auto
        @revert()
      else
        @submit()

    capture: (data, status, xhr) =>
      $('#finder').addClass('up')
      super

    revert: (e) =>
      $('#finder').removeClass('up')
      super



  # The suggestions form is a fast filter form with history support
  #
  $.fn.suggestion_form = (options) ->
    @each ->
      new SuggestionForm @, options
    @
  
  class SuggestionForm extends FilterForm
    @default_options: {
      fast: true
      auto: false
      into: "#suggestion_box"
    }

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

    capture: (e, data, status, xhr) =>
      super
      @saveState(data) if Modernizr.history

    revert: (e) =>
      super
      @saveState(null) if Modernizr.history
      
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
  # when its link is clicked. It could perhaps become a subclass of the generic toggle mechanism and benefit from its persistence.
      
  $.fn.folder = ->
    @each ->
      new Folder(@)
      
  class Folder
    constructor: (element) ->
      @_container = $(element)
      @_list = @_container.children('ul.filing')
      if @_list[0]
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
      console.log "name_field", @name_field, title
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
      width = @hook.outerWidth() - 2
      width = 300 if width < 300
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
      