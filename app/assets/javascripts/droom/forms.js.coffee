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
    constructor: (element, @_selector) ->
      @_container = $(element)
      @_showing_text = @_container.text().replace('show', 'hide').replace('Show', 'Hide')
      @_hiding_text = @_showing_text.replace('hide', 'show').replace('Hide', 'Show')
      @_container.click @toggle
      @_showing = $(@_selector).is(":visible")
      
    toggle: (e) =>
      e.preventDefault() if e
      if @_showing then @hide() else @show()

    show: =>
      $(@_selector).fadeIn()
      @_container.text(@_showing_text)
      @_showing = true
      
    hide: =>
      $(@_selector).fadeOut()
      @_container.text(@_hiding_text)
      @_showing = false

  $.fn.toggle = () ->
    @each ->
      new Toggle(@, $(@).attr('data-affected'))




  class Twister
    constructor: (element) ->
      @_twister = $(element)
      @_twisted = @_twister.siblings('.twisted')
      @_toggle = @_twister.find('a')
      @_toggle.click @toggle
      @close() if @_twister.hasClass('closed')

    toggle: (e) =>
      e.preventDefault() if e
      if @_twisted.is(':visible') then @close() else @open()
      
    open: () =>
      @_twister.removeClass("closed")
      @_twisted.slideDown "slow"

    close: () =>
      @_twisted.slideUp "slow", () =>
        @_twister.addClass("closed")
  
  $.fn.twister = ->
    @each ->
      new Twister(@)

  # A captive form submits via an ajax request and pushes its results into the present page.

  class CaptiveForm
    constructor: (element, @_options) ->
      @_form = $(element)
      @_prompt = @_form.find("input[type=\"text\"]")
      @_request = null
      @_original_content = $(@_options.replacing).clone()
      @_original_term = decodeURIComponent $.urlParam("q") if $.urlParam("q")
      if @_original_term
        @_prompt.val(@_original_term)
        @submit() unless @_prompt.val() is ""
      else
        @revert()
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
        url: @_form.attr("action") + ".js"
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
      @display @_original_content
      @_original_content.fadeTo "fast", 1
      @_prompt.val("")
      @saveState()
      
    display: (results) =>
      $(@_options.replacing).replaceWith results
      $(@_options.clearing).val "" if @_options.clearing?
      $(@_options.replacing).find('a.popup').popup_remote_content()
      $(@_options.replacing).find('a.cancel').click @revert

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
      @_form.on 'ajax:beforeSend', @pend
      @_form.on 'ajax:error', @fail
      @_form.on 'ajax:success', @receive
      @activate()
      
    activate: () => 
      @_form.find('a.cancel').click @cancel
      @_form.activate()
      @_options.on_prepare?()

    pend: (event, xhr, settings) =>
      xhr.setRequestHeader('X-PJAX', 'true')
      @_form.addClass('waiting')
      @_options.on_submit?()

    fail: (event, xhr, status) ->
      @_form.removeClass('waiting').addClass('erratic')
      @_options.on_error?()
  
    receive: (event, response, status) =>
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


  $.fn.remote_link = (callback) ->
    @
      .on 'ajax:beforeSend', (event, xhr, settings) ->
        $(@).addClass('waiting')
        xhr.setRequestHeader('X-PJAX', 'true')
      .on 'ajax:error', (event, xhr, status) ->
        console.log "remote_link error:", status
        $(@).removeClass('waiting').addClass('erratic')
      .on 'ajax:success', (event, response, status) ->
        $(@).removeClass('waiting')
        callback(response)



  $.fn.removes = (selector) ->
    selector ?= '.holder'
    @each ->
      affected = $(@).attr('data-affected')
      $(@).remote_link (response) =>
        $(@).parents(selector).first().fadeOut 'fast', () ->
          $(@).remove()
          $(affected).trigger "refresh"



  class Replacement
    constructor: (content, container) ->
      @_container = $(container)
      @_content = $(content)
      @_mask = $('#mask')
      @_original_content = @_container.html()
      @_container.html(@_content)

    revert: (e) =>
      @_container.html(@_original_content)
      @_container.signal_cancellation()

  $.fn.replace_with_remote_form = (container) ->
    @each ->
      container ?= $(@).parents('.holder')
      affected = $(@).attr('data-affected')
      $(@).remote_link (response) =>
        f = $(response)
        rp = new Replacement f, container
        new RemoteForm f, 
          on_cancel: rp.revert
          on_complete: (response) =>
            container.replaceWith(response)
            response.activate()
            response.signal_confirmation()
            $(affected).trigger "refresh"



  class Interjection
    constructor: (content, target, @_position) ->
      @_options = $.extend {position: 'after'}, @_opts
      @_content = $(content)
      @_mask = $('#mask')
      @_target = $(target)
      @_container = $('<div class="interjected" />')
      switch @_position
        when "insert" then @_container.prependTo(@_target)
        when "before" then @_container.insertBefore(@_target)
        when "after" then @_container.insertAfter(@_target)
        else throw "interjection overruled"
      @_container.hide().append(@_content)
      @show()
      
    show: (e) =>
      e.preventDefault() if e
      @_container.slideDown 'slow'

    hide: (e) =>
      e.preventDefault() if e
      @_container.slideUp 'slow'

    remove: (e) =>
      e.preventDefault() if e
      @_container.slideUp 'fast', () ->
        $(@).remove()

  $.fn.interject = (target, position) ->
    position ?= 'after'
    @each ->
      new Interjection @, target, position

  $.fn.append_remote_form = (target) ->
    @each ->
      target ?= $(@).parent()
      affected = $(@).attr('data-affected')
      
      $(@).remote_link (response) =>
        f = $(response)
        ij = new Interjection f, target, 'after'
        new RemoteForm f, 
          on_cancel: ij.remove
          on_complete: () =>
            $(affected).trigger "refresh"




  class Overlay
    constructor: (content, marker) ->
      @_content = $(content)
      @_marker = $(marker)
      @_container = $('<div class="overlay" />')
      @_mask = $('#mask')
      @_marker.offsetParent().append(@_container)
      @_container.hide().append(@_content)
      position = 
        top: @_marker.position().top
        left: @_marker.position().left
      @_container.css position
      @show()
      

    show: (e) =>
      e.preventDefault() if e
      @_mask.bind "click", @hide
      @_mask.fadeTo 'fast', 0.8
      @_container.fadeIn 'fast'

    hide: (e) =>
      e.preventDefault() if e
      @_mask.fadeOut('slow')
      @_mask.unbind "click", @hide
      @_container.fadeOut('slow')
    
    remove: (e) =>
      @_mask.fadeOut('fast')
      @_mask.unbind "click", @hide
      @_container.fadeOut 'slow', () ->
        $(@).remove()
      

  $.fn.overlay_remote_form = () ->
    @each ->
      $(@).remote_link (response) =>
        marker = $(@).parents('.holder')
        affected = $(@).attr('data-affected')
        f = $(response)
        ov = new Overlay f, marker
        new RemoteForm f, 
          on_cancel: ov.remove
          on_complete: (response) =>
            ov.remove()
            marker.replaceWith(response)
            response.activate()
            response.signal_confirmation()
            $(affected).trigger "refresh"


  class Popup
    constructor: (content) ->
      @_content = $(content)
      @_mask = $('#mask')
      @_container = $('<div class="popup" />')
      @_container.insertAfter(@_mask).hide().append(@_content)
      @_content.find('a.cancel').click @hide
      @_content.activate()
      @show()

    show: (e) =>
      e.preventDefault() if e
      @_container.fadeTo('fast', 1)
      @_mask.fadeTo('fast', 0.8)
      @_mask.bind "click", @hide

    hide: (e) =>
      e.preventDefault() if e
      @_container.fadeOut('fast')
      @_mask.fadeOut('fast')
      @_mask.unbind "click", @hide

  $.fn.popup_remote_content = () ->
    @remote_link (response) ->
      new Popup(response)


  class Refresher
    constructor: (element) ->
      @_container = $(element)
      @_url = @_container.attr 'data-url'
      @_container.bind "refresh", @refresh
      
    refresh: () =>
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
      e.preventDefault() if e
      @_fields.hide()
      @_notifier = $('<div class="notifier"></div>').appendTo @_form
      @_label = $('<h2 class="filename"></div>').appendTo @_notifier
      @_progress = $('<div class="progress"></div>').appendTo @_notifier
      @_bar = $('<div class="bar"></div>').appendTo @_progress
      @_status = $('<div class="status"></div>').appendTo @_notifier
      @_label.text(@_filename)
      @send()
      
    showSelection: () =>
      @_filename = @_file.name.split(/[\/\\]/).pop()
      @_ext = @_filename.split('.').pop()
      @_link.addClass(@_ext) if @_ext in @_extensions
      $('input.name').val(@_filename) if $('input.name').val() is ""

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
          $('[data-tag="update_on_insert"]').trigger("refresh")
    
    finish: (e) =>
      @_status.text("Processing")
      @_bar.css
        "background-color": "green"



  $.fn.file_picker = () ->
    @each ->
      new FilePicker(@)

  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()
