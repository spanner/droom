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
    return 0  unless results
    results[1] or 0
    


  class Toggle
    constructor: (element, selector) ->
      @_container = $(element)
      @_affected = $(selector)
      @_showing_text = @_container.text().replace('show', 'hide').replace('Show', 'Hide')
      @_hiding_text = @_showing_text.replace('hide', 'show').replace('Hide', 'Show')
      @_container.click @toggle
      @_showing = @_affected.is(":visible")
      
    toggle: (e) =>
      e.preventDefault() if e
      if @_showing then @hide() else @show()

    show: =>
      console.log "showing toggle", @_container, @_showing_text
      @_affected.show()
      @_container.text(@_showing_text)
      @_showing = true
      
    hide: =>
      console.log "hiding toggle", @_container, @_hiding_text
      @_affected.hide()
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
      console.log "toggle", @_twisted
      e.preventDefault() if e
      if @_twisted.is(':visible') then @close() else @open()
      
    open: () =>
      console.log "open"
      @_twister.removeClass("closed")
      @_twisted.slideDown "slow"

    close: () =>
      console.log "close"
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
      @_original_term = decodeURIComponent($.urlParam("p")) unless decodeURIComponent($.urlParam("p")) is "0"
      if @_original_term
        @_prompt.val(@_original_term)
        @submit() unless @_prompt.val() is ""
      else
        @revert()
      @_form.submit @submit
      if @_options.fast
        @_form.find("input[type=\"text\"]").keyup @keyed
        @_form.find("input[type=\"radio\"]").click @submit
        @_form.find("input[type=\"checkbox\"]").click @submit
      if Modernizr.history
        $(window).bind 'popstate', @restoreState
      
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
        url = window.location.pathname + '?p=' + encodeURIComponent(term)
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
      @_stylesheets = ["/assets/application.css", "http://fast.fonts.com/cssapi/bca9b200-3c71-403e-a64f-7192988f33be.css"]
      @_editor = new wysihtml5.Editor @_textarea.attr('id'),
        stylesheets: @_stylesheets,
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
      


  class TemporaryOverlay
    constructor: (content, container) ->
      @_content = $(content)
      @_holder = $(container)
      @_container = $('<div class="wrapper" />')
      @_mask = $('#mask')
      @_holder.append @_container
      @_container.hide().append(@_content).activate()
      @_content.find('a.cancel').click @hide
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


  $.fn.overlay_remote_content = () ->
    @each ->
      $(@).remote_link (response) =>
        new TemporaryOverlay response, $(@).parents('.holder')



  class Interjection
    constructor: (content, target, @_position) ->
      @_options = $.extend {position: 'after'}, @_opts
      @_content = $(content)
      @_mask = $('#mask')
      @_target = $(target)
      @_container = $('<div class="interjected" />')
      switch @_position
        when "prepend" then @_container.prependTo(@_target)
        when "append" then @_container.appendTo(@_target)
        when "before" then @_container.insertBefore(@_target)
        when "after" then @_container.insertAfter(@_target)
        else throw "bad interjection"

      @_container.hide().append(@_content)
      @_content.activate()
      @_content.find('a.cancel').click @hide
      @show()
      
    show: (e) =>
      e.preventDefault() if e
      @_mask.fadeTo('fast', 0.8)
      @_container.slideDown('fast')

    hide: (e) =>
      e.preventDefault() if e
      @_mask.fadeOut('slow')
      @_container.slideUp('slow')

  $.fn.prepend_remote_content = (target) ->
    @each ->
      target ?= $(@).attr('data-target')
      $(@).remote_link (response) =>
        new Interjection response, target, 'prepend'


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

    hide: () =>
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
      
