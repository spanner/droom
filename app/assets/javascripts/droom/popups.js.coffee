jQuery ($) ->

  ## Popups
  #
  # This is the modal overlay we use for most creation and editing tasks. No special setup is required: any link can
  # be turned into a popup-form-generator just by calling
  #   
  #   $(link).popup()
  #
  # Display of the popup form is handled by the Popup class. The requests involved in retrieving, submitting and 
  # resubmitting the form are built on the usual `remote_form` and `remote_link` methods, both of which just configure
  # the rails_ujs remote links. All this is held together by callbacks triggered in the remote_link mechanism. The
  # callbacks are defined anonymously as part of the `$().popup()` method below.
  #
  # We don't attempt to update the page directly with a server response, but a `data-affected` attribute can be used to 
  # trigger a refresh event on any DOM element that should be updated after this action completes. If those elements
  # have (or are within) refreshable behaviour, they will be updated from the server. See 'affecting the page' above.
  #
  $.fn.popup = () ->
    @each ->
      new Popup(@)
          
  class Popup
    constructor: (element) ->
      @_link = $(element)
      @_iteration = 0
      @_affected = @_link.attr('data-affected')
      @_replaced = @_link.attr('data-replaced')
      @_link.remote
        on_request: @begin
        on_success: @receive

    begin: (xhr) =>
      switch @_iteration
        when 0
          @prepare()
        when 1
          # a popup that it is still displaying the first response will just be shown again.
          @show()
          return false
        else
          # A popup that is on a second or later response will be considered abandoned and started again.
          @reset()
          @prepare()

    getContainer: () =>
      $('<div class="popup" />')

    prepare: () =>
      @_mask = $('<div class="mask" />').appendTo($('body'))
      @_container = @getContainer()
      @_container.bind 'close', @hide
      @_container.bind 'finished', @conclude
      @_container.bind 'resize', @place
      @_container.insertAfter(@_mask).hide()

    receive: (data) =>
      if @_iteration == 0 || $(data).find('form').length
        @display(data)
      else
        @conclude(data)
        
    display: (data) =>
      @_iteration++
      @_content = $(data)
      @_container.empty()
      @_container.append(@_content)
      @_content.activate()
      @_header = @_content.find('.header')
      @_content.find('form').remote
        on_cancel: @hide
        on_success: @receive
      @show()
          
    conclude: (data) =>
      if @_affected
        $(@_affected).trigger "refresh"
      if @_replaced
        replacement = $(data)
        $(@_replaced).after(replacement)
        $(@_replaced).remove()
        replacement.activate().signal_confirmation()
      @reset()

    show: (e) =>
      e.preventDefault() if e
      @place()
      unless @_container.is(":visible")
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
      @_container.find('iframe.youtube').sendCommand('pauseVideo')
      

    reset: () =>
      @hide()
      @_container.remove()
      @_iteration = 0

    place: (e) =>
      cols = @_container.find("div.column").not('.hidden').length
      if cols
        width = (cols * 280) + 40
      else 
        width = @_container.children().first().width() || 580
      w = $(window)
      height_limit = w.height() - 100
      height = [@_container.height(), height_limit].min()
      left = parseInt((w.width() - width) / 2)
      top = parseInt((w.height() - height - 40) / 2)  # allowing for padding
      placement = 
        left: left
        top: top
        width: width
        "max-height": height_limit
      if @_container.is(":visible")
        @_container.animate placement
      else
        @_container.css placement



  # Popup forms will usually contain one or more .column divs. The columns are a standard width and
  # the number of columns determines the width of the popup. Columns can also be hidden, initially,
  # then revealed if the user clicks a 'more' or 'detail' link. The expander action is defined here.
  #
  $.fn.column_expander = (popup) ->
    @click (e) ->
      e.preventDefault() if e
      link = $(@)
      container = link.parents('popup').first()
      if affected = link.attr('data-affected')
        # swap between text and the alt text held in data-alt
        text = link.text()
        alt = link.attr('data-alt')
        link.text(alt).attr('data-alt', text)
        # Point in the other direction
        if link.hasClass('left') then link.addClass('right').removeClass('left') else link.addClass('left').removeClass('right')
        # Toggle visibility of the column.
        # Contained form fields are disabled when hidden, detaching them from form submission.
        container.find(affected).each (i, col) ->
          if $(col).is(":visible")
            $(col).addClass('hidden').find('input, select, textarea').attr('disabled', true)
          else
            $(col).removeClass('hidden').find('input, select, textarea').removeAttr('disabled')
        # We finish by triggering a resize event on the popup container, which will trigger a place() on the popup..
        container.trigger('resize')





  # The action menu is a simple popup submenu used to hide editing links.
  #
  $.fn.action_menu = ->
    @each ->
      new ActionMenu(@)
    @

  class ActionMenu
    @menus: $()
    @remember: (menu) ->
      @menus.push(menu)
    @hideAll: () ->
      menu.hide() for menu in @menus

    constructor: (element) ->
      @_link = $(element)
      @_selector = "[data-for=\"#{@_link.attr('data-menu')}\"]"
      @_link.click @toggle
      ActionMenu.remember(@)

    place: =>
      pos = @_link.position()
      $(@_selector).css
        top: pos.top + 20
        left: pos.left

    toggle: (e) =>
      if e
        e.preventDefault() 
        e.stopPropagation()
      if @_link.hasClass('up') then @hide() else @show()

    show: (e) =>
      @place()
      ActionMenu.hideAll()
      @_link.addClass('up')
      $(@_selector).first().stop().slideDown 'fast'
      $(document).bind "click", @hide
    
    hide: (e) =>
      $(@_selector).first().stop().slideUp 'fast', () =>
        @_link.removeClass('up')
      $(document).unbind "click", @hide



  class Panel
    @panels: $()
    @remember: (panel) ->
      @panels.push(panel)
    @hideAll: () ->
      panel.hide() for panel in @panels

    constructor: (element) ->
      @container = $(element)
      @id = @container.attr('data-panel')
      @links = $("a[data-panel='#{@id}']")
      @header = $('.masthead').find("a[data-panel='#{@id}']")
      @patch = $('<div class="patch" />').appendTo($('body'))
      @links.bind "click", @toggle
      @container.bind "show", @show
      @set()
      Panel.remember(@)
    
    setup: () =>
      offset = @header.offset()
      @patch.css
        left: offset.left
        top: offset.top + @header.height() - 3
        width: @header.outerWidth() - 2
      @container.css
        left: offset.left - (@container.outerWidth() - @header.outerWidth()) / 3
        top: offset.top + @header.height() + 5
      
    set: () =>
      if @container.hasClass('here') then @show() else @hide()
      
    toggle: (e) =>
      if e
        e.preventDefault()
        e.stopPropagation()
      if @container.is(":visible") then @revert() else @show()

    hide: (e) =>
      @container.stop().fadeOut()
      @patch.stop().fadeOut()
      @header.removeClass('up')
      $(document).unbind "click", @hide
    
    show: (e) =>
      @setup()
      Panel.hideAll()
      @container.stop().fadeIn('fast')
      @patch.stop().fadeIn('fast')
      @header.addClass('up')
  
    revert: (e) =>
      Panel.hideAll()
    

  $.fn.panel = ->
    @each ->
      new Panel(@)
    @

