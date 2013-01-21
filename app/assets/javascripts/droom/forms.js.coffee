jQuery ($) ->

  # minimal rfc4122 generator taken from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
  $.makeGuid = ()->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random()*16|0
      v = if c is 'x' then r else r & 0x3 | 0x8
      v.toString 16

  # Query string parser for history-restoration purposes.

  $.urlParam = (name) ->
    results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(window.location.href)
    return false unless results
    results[1] or 0



  class Toggle
    constructor: (element, @_selector, @_name) ->
      @_container = $(element)
      @_name ?= "droom_#{@_selector}_state"
      @_showing_text = @_container.text().replace('show', 'hide').replace('Show', 'Hide')
      @_hiding_text = @_showing_text.replace('hide', 'show').replace('Hide', 'Show')
      @_container.click @toggle
      if cookie = $.cookie(@_name)
        @_showing = cookie is "showing"
        @apply()
      else
        @_showing = $(@_selector).is(":visible")
        @store()
      
    apply: (e) =>
      e.preventDefault() if e
      if @_showing then @show() else @hide()

    toggle: (e) =>
      e.preventDefault() if e
      if @_showing then @slideUp() else @slideDown()

    slideDown: =>
      @_container.addClass('showing')
      $(@_selector).slideDown () =>
        @show()

    show: =>
      $(@_selector).show()
      @_container.addClass('showing')
      @_container.text(@_showing_text)
      @_showing = true
      @store()
    
    slideUp: =>
      $(@_selector).slideUp () =>
        @hide()
      
    hide: =>
      $(@_selector).hide()
      @_container.removeClass('showing')
      @_container.text(@_hiding_text)
      @_showing = false
      @store()
      
    store: () =>
      value = if @_showing then "showing" else "hidden"
      $.cookie @_name, value,
         path: '/'


  $.fn.toggle = () ->
    @each ->
      new Toggle(@, $(@).attr('data-affected'))




  class Twister
    @currently_open: []
    constructor: (element) ->
      @_twister = $(element)
      @_twisted = @_twister.find('.twisted')
      @_toggles = @_twister.find('a.twisty')
      @_toggles.click @toggle
      @_open = @_twister.hasClass("showing")
      @set()

    set: () =>
      if @_open then @open() else @close()
      
    toggle: (e) =>
      e.preventDefault() if e
      if @_open then @close() else @open()
      
    open: () =>
      @_twister.addClass("showing")
      @_twisted.show()
      @_open = true
      Twister.currently_open.push(@_id)
      
    close: () =>
      @_twister.removeClass("showing")
      @_twisted.hide()
      @_open = false
      Twister.currently_open.remove(@_id)  # remove is defined in lib/extensions

  $.fn.twister = ->
    @each ->
      new Twister(@)



  $.fn.replace_with_remote_content = (selector) ->
    selector ?= '.reviewer'
    @each ->
      $(@).remote_link
        on_complete: (r) =>
          replaced = $(@).parents(selector)
          replacement = $(r).insertAfter(replaced)
          replaced.remove()
          replacement.activate()





  # A captive form submits via an ajax request and pushes its results into the present page.

  class CaptiveForm
    constructor: (element, @_options) ->
      @_form = $(element)
      @_prompt = @_form.find("input[type=\"text\"]")
      @_request = null
      @_original_content = $(@_options.replacing)
      @_placed_content = null
      @_original_term = decodeURIComponent $.urlParam("q") if $.urlParam("q")
      if @_original_term
        @_prompt.val(@_original_term)
        @submit() unless @_prompt.val() is ""
      else
        # @revert()
      if @_options.fast
        @_form.find("input[type=\"text\"]").keyup @keyed
        @_form.find("input[type=\"radio\"]").click @submit
        @_form.find("input[type=\"checkbox\"]").click @submit
      if Modernizr.history
        $(window).bind 'popstate', @restoreState
      @_form.submit @submit
      
    keyed: (e) =>
      k = e.which
      if (k >= 32 and k <= 165) or k == 8
        if @_prompt.val() == ""
          @revert()
        else
          @_form.submit()
    
    submit: (e) =>
      e.preventDefault() if e
      $(@_options.replacing).fadeTo "fast", 0.2
      @_request.abort() if @_request
      @_form.find("input[type='submit']").addClass "waiting"
      @_request = $.ajax
        type: "GET"
        dataType: "html"
        url: @_form.attr("action")
        data: @_form.serialize()
        success: @update
    
    update: (results) =>
      @_form.find("input[type='submit']").removeClass "waiting"
      @saveState(results) if Modernizr.history
      @display results
    
    saveState: (results) =>
      results ?= @_original_content.html()
      term = @_prompt.val()
      if term
        url = window.location.pathname + '?q=' + encodeURIComponent(term)
      else
        url = window.location.pathname
      state = 
        html: results
        term: term
      history.pushState state, "New page title", url
    
    restoreState: (e) =>
      event = e.originalEvent
      if event.state? && event.state.html?
        @display event.state.html
        @_prompt.val(event.state.term)
      
    revert: (e) =>
      e.preventDefault() if e
      @_placed_content?.remove()
      @_original_content?.fadeTo "fast", 1
      @_prompt.val("")
      @saveState()
      
    display: (results) =>
      replacement = $(results)
      @_placed_content?.remove()
      @_original_content?.hide()
      @_original_content?.before(replacement)
      $(@_options.clearing).val "" if @_options.clearing?
      replacement.find('a.cancel').click @revert
      @_placed_content = replacement

  $.fn.captive = (options) ->
    options = $.extend(
      replacing: "#results"
      clearing: null
    , options)
    @each ->
      new CaptiveForm @, options
    @

  class Editor
    constructor: (element) ->
      @_container = $(element)
      @_textarea = @_container.find('textarea')
      @_toolbar = @_container.find('.toolbar')
      @_toolbar.attr('id', $.makeGuid()) unless @_toolbar.attr('id')?
      @_textarea.attr('id', $.makeGuid()) unless @_textarea.attr('id')?
      stylesheets = $("link").map ->
        $(@).attr('href')
      @_editor = new wysihtml5.Editor @_textarea.attr('id'),
        stylesheets: stylesheets,
        toolbar: @_toolbar.attr('id'),
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

  $.fn.html_editable = ()->
    @each ->
      new Editor(@)





  class RemoteForm
    constructor: (element, opts) ->
      @_form = $(element)
      @_options = $.extend {}, opts
      @_form.attr('data-remote', true)
      @_form.attr('data-type', 'html')
      @_form.on 'ajax:beforeSend', @pend
      @_form.on 'ajax:error', @fail
      @_form.on 'ajax:success', @receive
      @activate()
      
    activate: () => 
      @_form.find('a.cancel').click @cancel
      # @_form.activate()
      @_options.on_prepare?()

    pend: (event, xhr, settings) =>
      event.stopPropagation()
      xhr.setRequestHeader('X-PJAX', 'true')
      @_form.addClass('waiting')
      @_options.on_submit?()

    fail: (event, xhr, status) ->
      event.stopPropagation()
      @_form?.removeClass('waiting').addClass('erratic')
      @_options.on_error?()
  
    receive: (event, response, status) =>
      event.stopPropagation()
      replacement = $(response)
      @_form.after(replacement)
      @_form.remove()
      if replacement.is('form')
        @_form = replacement
        @activate()
        #todo: make sure we get error markers displaying nicely here
      else
        @_options.on_complete?(replacement)
        
    cancel: (e) =>
      e.preventDefault() if e
      if @_options.on_cancel?
        @_options.on_cancel()
      else
        @_form.remove()

  $.fn.remote_form = (opts) ->
    @each ->
      new RemoteForm @, opts 


  class RemoteLink
    constructor: (element, opts) ->
      @_link = $(element)
      @_options = $.extend {}, opts
      @_link.attr('data-type', 'html')
      @_link.on 'ajax:beforeSend', @pend
      @_link.on 'ajax:error', @fail
      @_link.on 'ajax:success', @receive

    pend: (event, xhr, settings) =>
      event.stopPropagation()
      xhr.setRequestHeader('X-PJAX', 'true')
      @_link.addClass('waiting')
      @_options.on_request?(event, xhr, settings)

    fail: (event, xhr, status) ->
      event.stopPropagation()
      @_form?.removeClass('waiting').addClass('erratic')
      @_options.on_error?(event, xhr, status)
  
    receive: (event, response, status) =>
      event.stopPropagation()
      @_link.removeClass('waiting')
      @_options.on_complete?(response)

      
  $.fn.remote_link = (opts) ->
    @each ->
      new RemoteLink @, opts 


  $.fn.removes = (selector) ->
    selector ?= '.holder'
    @each ->
      affected = $(@).attr('data-affected')
      $(@).remote_link 
        on_complete: (response) =>
          $(@).parents(selector).first().fadeOut 'fast', () ->
            $(@).remove()
          $(affected).trigger "refresh"


  class Popup
    constructor: (content, marker) ->
      @_content = $(content)
      @_marker = $(marker) if marker
      @_header = @_content.find('h2')
      @_mask = $('<div class="mask" />').appendTo($('body'))
      @_container = $('<div class="popup" />')
      @_container.insertAfter(@_mask).hide().append(@_content)
      @_closer = $('<a href="#" class="closer">close</a>').appendTo(@_header)
      @_container.activate()
      @_container.find('a[data-action="column_toggle"]').column_expander(@)
      @_container.find('.hidden').find('input, select, textarea').attr('disabled', true)
      @_closer.click(@hide)
      @show()
      
    place: (e) =>
      cols = @_container.find("div.column").not('.hidden').length
      if cols
        width = (cols * 280) - 20
      else 
        width = 540
      w = $(window)
      height_limit = w.height() - 80
      height = [@_container.height(), height_limit].min()
      left = parseInt((w.width() - width) / 2)
      top = parseInt((w.height() - height) / 3)
      placement = 
        left: left
        top: top
        width: width
        "max-height": height_limit
      
      if @_container.is(":visible")
        @_container.animate placement
      else
        @_container.css placement
    
    toggle_column: (selector) =>
      @_container.find(selector).each (i, col) =>
        if $(col).is(":visible")
          $(col).addClass('hidden').find('input, select, textarea').attr('disabled', true)
        else
          $(col).removeClass('hidden').find('input, select, textarea').removeAttr('disabled')
      @place()
          
      
    show: (e) =>
      e.preventDefault() if e
      @place()
      @_container.fadeTo 'fast', 1, () =>
        @_container.find('[data-focus]').focus()
      @_mask.fadeTo('fast', 0.8)
      @_mask.bind "click", @hide
      $(window).bind "resize", @place

    hide: (e) =>
      e.preventDefault() if e
      @_container.fadeOut('fast')
      @_mask.fadeOut('fast')
      @_mask.unbind "click", @hide
      $(window).unbind "resize", @place


  $.fn.popup_remote_content = () ->
    @each ->
      popup = null
      link = $(@)
      marker = link.parents('.holder')
      affected = link.attr('data-affected')
      replaced = link.attr('data-replaced')
      
      link.attr('data-type', 'html')
      link.remote_link
        on_request: () ->
          if popup
            link.removeClass('waiting')
            popup.show()
            return false

        on_complete: (r) ->
          response = $(r)
          popup = new Popup response, marker
          response.find('form').remote_form
            on_cancel: popup.hide
            on_complete: (form_response) ->
              replacement = $(form_response)
              popup.hide()
              popup = null
              $(affected).trigger "refresh"
              if replaced
                $(replaced).replaceWith replacement
                replacement.activate().signal_confirmation()
              

  $.fn.column_expander = (popup) ->
    @click (e) ->
      e.preventDefault() if e
      link = $(@)
      if affected = link.attr('data-affected')
        text = link.text()
        alt = link.attr('data-alt')
        link.text(alt).attr('data-alt', text)
        if link.hasClass('left')
          link.addClass('right').removeClass('left')
        else
          link.addClass('left').removeClass('right')
        popup.toggle_column(affected)



  class Refresher
    constructor: (element) ->
      @_container = $(element)
      @_url = @_container.attr 'data-url'
      @_container.bind "refresh", @refresh
      
    refresh: (e) =>
      e.stopPropagation()
      e.preventDefault()
      $.ajax @_url,
        dataType: "html"
        success: @replace
    
    replace: (data, textStatus, jqXHR) =>
      replacement = $(data)
      @_container.fadeOut 'fast', () =>
        replacement.hide().insertAfter(@_container)
        @_container.remove()
        @_container = replacement
        @_container.activate().fadeIn('fast')
      
  $.fn.refresher = () ->
    @each ->
      new Refresher @



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


  $.fn.submitter = ->
    @click (e) ->
      $(@).addClass('waiting').text('Please wait').bind "click", (e) =>
        # e.preventDefault() if e



  class Copier
    constructor: (element) ->
      @_link = $(element)
      @_link.click @failed
      @_link.wrap $('<div class="copyholder" />')
      @_container = @_link.parents('.copyholder')
      @_clip = new ZeroClipboard.Client()
      @_clip.setHandCursor true
      @_clip.setText(@_link.attr('data-value').replace(/^\s+/gm, ''))
      
      [w, h] = [@_link.width() || 60, @_link.height() || 15]
      @_clip_element = @_clip.getHTML(w, h+5)
      $(@_clip_element).appendTo @_container

      @_clip.addEventListener 'complete', @complete
      @_clip.addEventListener 'onMouseOver', @hover
      @_clip.addEventListener 'onMouseOut', @unHover

    hover: (e) =>
      @_link.addClass('hover')

    unHover: (e) =>
      @_link.removeClass('hover')
      
    complete: (client, text) =>
      @_link.signal_confirmation()

    failed: (e) =>
      e.preventDefault()
      
  $.fn.copier = ->
    ZeroClipboard.setMoviePath( '/assets/droom/lib/ZeroClipboard.swf' );
    @each ->
      new Copier @


