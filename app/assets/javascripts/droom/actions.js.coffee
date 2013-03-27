# This is a collection of useful interface behaviours. Most of them are form- or input-based. They shouldn't ever
# be object-specific, but can be used throughout the droom interface to make forms and other controls more lively.
#
# The basic approach here is PJAX: our remote calls always return chunks of html. There are no client-side templates
# or model classes. Instead we have defined a set of actions, by which page elements can interact with the server in
# structured ways. A tag will declare that it triggers an action, and may also declare that the action will replace or
# affect other elements. 
#
# Many elements are refreshable, and an action that affects them will trigger their refreshment. Editing an event is
# a simple remote form operation with several consequences for the page:
#
#   link_to t(:edit_event), edit_event_url(event), :class => 'edit minimal', :data => {
#      :action => "popup", 
#      :replaced => "#event_#{event.id}", 
#      :affected => ".minimonth"
#   }
#
# When the `popup` action is complete - that is, the server returns a response with no form in it - the final response 
# will replace the original event container and the small calendar display will be refreshed to show the possibly revised
# date of the event.
#
# It is our hope that this simple non-architecture will make it easy to support a future pub-sub update.

jQuery ($) ->

  ## Affecting the page
  #
  # refreshable, affected rules, etc.

  $.fn.refresher = () ->
    @each ->
      new Refresher @

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
      

  # ## Actions
  #
  # The 'remove' action takes out the parent element of this node designated by the usual 'affected'
  # attribute. The delete link next to an event, for example:
  #
  #   link_to t(:remove), event_url(event), :method => 'delete', :data => {
  #     :confirm => t(:confirm_delete_event, :name => event.name), 
  #     :removes => ".holder",
  #     :affected => ".minimonth"}
  #
  # ...will (on success) remove the first containing '.holder' element and also refresh the mini calendar display.
  #
  $.fn.removes = () ->
    @each ->
      removed = $(@).attr('data-removed') || ".holder"
      affected = $(@).attr('data-affected')
      
      $(@).remote
        on_success: (response) =>
          $(@).parents(removed).first().fadeOut 'fast', () ->
            $(@).remove()
            $(affected).trigger "refresh"


  $.fn.affects = () ->
    @each ->
      affected = $(@).attr('data-affected')
      $(@).remote
        on_success: (response) =>
          $(affected).trigger "refresh"


  # Close links work just by triggering a 'hide' event and hoping that something further up the tree will bind
  # it to the right thing.

  $.fn.closes = () ->
    @click (e) ->
      e.preventDefault()
      $(@).trigger('close')



  # *replace_with_remote_content* is a useful shortcut for links and forms that should simply be replaced with the
  # result of their action.
  #
  $.fn.replace_with_remote_content = (selector, opts) ->
    selector ?= '.holder'
    options = $.extend { force: false }, opts
    @each ->
      container = $(@).attr('data-replaced') || selector
      affected = $(@).attr('data-affected')
      $(@).remote
        on_success: (r) =>
          replaced = $(@).self_or_ancestor(container).last()
          replacement = $(r).insertAfter(replaced)
          replaced?.remove()
          replacement.activate()
          $(affected).trigger('refresh')
      $(@).click() if options['force']




  # The submitter is a self-disabling submit button that can only be clicked once.
  #
  $.fn.submitter = ->
    @each ->
      button = $(@)
      button.parents('form').bind "submit", (e) ->
        button.addClass('waiting').text('Please wait').bind "click", (e) =>
          e.preventDefault() if e


  # The toggle action shows or hides the affected elements with cookie-based persistence across page
  # views. A link like this:
  #
  #   %a{:data => {:action => 'toggle', :affected => '.admin'}}
  #
  # will toggle on and off the display of anything with the 'admin' class.
  #
  $.fn.toggle = () ->
    @each ->
      new Toggle(@, $(@).attr('data-affected'))

  #todo: make this a more versatile base class
  class Toggle
    constructor: (element, @_selector, @_name) ->
      @_container = $(element)
      @_name ?= "droom_#{@_selector}_state"
      @_showing_text = @_container.text().replace('show', 'hide').replace('Show', 'Hide').replace('more', 'less').replace('More', 'Less')
      @_hiding_text = @_showing_text.replace('hide', 'show').replace('Hide', 'Show').replace('less', 'more').replace('Less', 'More')
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


  # The collapser is a self-expanding unit. Basically a toggle. #todo: amalgamate!

  $.fn.collapser = (options) ->
    @each ->
      new Collapser(@, options)
    @

  class Collapser
    constructor: (element, opts) ->
      @container = $(element)
      @options = $.extend {
        toggle: ".heading a.name"
        body: ".detail"
        preview: ".preview"
      }, opts
      @id = @container.attr('id')
      @switch = @container.find(@options.toggle)
      @body = @container.find(@options.body)
      @preview = @container.find(@options.preview)
      @switch.click @toggle
      @set()
      
    set: () =>
      if @container.hasClass("open") then @show() else @hide()
      
    toggle: (e) =>
      e.preventDefault() if e
      if @container.hasClass("open") then @hide() else @show()

    hide: () =>
      @container.removeClass('open')
      @preview.show().css('position', 'relative')
      @body.stop().slideUp 
        duration: 'slow'
        easing: 'glide'
        complete: =>
          @body.hide()

    show: () =>
      @container.addClass('open')
      @preview.css('position', 'absolute')
      @body.stop().slideDown
        duration: 'normal'
        easing: 'boing'
        complete: =>
          @preview.hide().css('position', 'relative')


  # this one just shows or hides based on whether a checkbox is checked

  $.fn.reveals = () ->
    @each ->
      new Revealer(@)

  class Revealer
    constructor: (element) ->
      @_checkbox = $(element)
      @_affected = @_checkbox.attr('data-affected')
      @_converse = @_checkbox.attr('data-converse')
      @_checkbox.bind "click", @set
      @set()
      console.log "revealer reveals", @_affected, $(@_affected)
      
    set: () =>
      if @_checkbox.is(":checked") then @show() else @hide()

    show: (e) =>
      $(@_affected).stop().slideDown()
      $(@_converse).stop().slideUp()

    hide: (e) =>
      $(@_affected).stop().slideUp()
      $(@_converse).stop().slideDown()


  # Yet another toggle, preserved for cdr reviewers but I hope not for long.

  $.fn.twister = ->
    @each ->
      new Twister(@)

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



  # The *alternator* action is a more extreme toggle. It allows an element to declare its alternate: 
  # when a link within the element is clicked, it will be removed from the DOM and its alternate
  # inserted. Usually the relation is reciprocal, so that another link in the alternate will bring
  # the original element back.
  #
  # The main use for this is to have two alternative blocks of form inputs: one to add a new associate
  # and one to choose from the existing list.
  #
  class Alternator
    constructor: (element) ->
      @_container = $(element)
      @_selector = @_container.attr("data-selector")
      @_alternate = @_container.siblings(@_selector)
      @revert()

    flip: (e) =>
      e.preventDefault() if e
      @_container.after(@_alternate)
      @_container.remove()
      @_alternate.find('a').click @revert
      
    revert: (e) =>
      e.preventDefault() if e
      @_alternate.before(@_container)
      @_alternate.remove()
      @_container.find('a').click @flip
      
  $.fn.alternator = ->
    @each ->
      new Alternator(@)






  # The *copier* action uses ZeroClipboard to put on the clipboard whatever is in our data-value attribute.
  #
  $.fn.copier = ->
    ZeroClipboard.setMoviePath( '/assets/droom/lib/ZeroClipboard.swf' );
    @each ->
      new Copier @

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
      
      
  # The main search page hasn't had much love yet.
  #
  # If we keep the inline functionality it should probably use the standard captive form.

  $.fn.search = ->
    @each ->
      new Search @

  class Search
    constructor: (element) ->
      @form = $(element)
      @search_box = @form.find(".search_box")
      @container = $(".search_results")
      @filters = @form.find "input[type='checkbox']"
      @search_box.on "keyup", @submit
      @filters.on "change", @submit

    submit: =>
      $.ajax
        url: "#{@form.attr('action')}?#{@form.serialize()}"
        type: "GET"
        dataType: "script"
        complete: (data) =>
          @container.replaceWith data.responseText
          @container = $(".search_results")

  #todo: Dragsort also needs to use Remote.

  $.fn.drag_sort = (options) ->
    @each ->
      first = 0
      offset = 1 + first
      sorter = $(@).sortable
        handle: ".handle"
      $.each $(@).children(), (i, child) =>
        $(child).bind "dragend", (e) =>
          child = $(child)
          index = child.index() + offset
          id = parseInt(child.attr('id').split("person_")[1], 10)
          $.ajax
            url: "/people/#{id}"
            type: "PUT"
            dataType: "JSON"
            data:
              person:
                position: index


  #todo: this has been replaced with the filterform.

  $.fn.search_filter = () ->
    @each ->
      new Filter @
    @

  class Filter
    constructor: (element) ->
      @_container = $(element)
      @_defilter = $('<a href="#" class="defilter" />').insertAfter(@_container)
      @_affected = @_container.attr('data-affected')
      @setDefilter()
      @_container.bind "keyup", @setQuery
      @_defilter.bind "click", @clearQuery
      # @announce()

    setDefilter: () =>
      if @_container.val()
        @_defilter.show()
      else
        @_defilter.hide()
      
    setQuery: (e) =>
      kc = e.which
      #   delete,     backspace,    alphanumerics,    number pad,        punctuation
      if (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
        @setDefilter()
        @filter()
        
    clearQuery: (e) =>
      e.preventDefault() if e
      @_container.val("")
      @setDefilter()
      @filter()

    filter: () =>
      $(@_affected).trigger "filter", @_container.val()





  # A text input that sizes to fit will adjust its font size to suit the length of its content.
  # At the moment this is done just by fitting a curve, but it ought really to be based on a 
  # calculation of area occupied.

  $.size_to_fit = (e) ->
    container = $(@)
    l = container.val().length
    size = if l then (((560.0/(2 * l+150.0)) + 0.25)).toFixed(2) else 1
    container.stop().animate
      'font-size': "#{size}em"
      width: 532
      height: 290
    , 
      queue: false
      duration: 100
        
  $.fn.self_sizes = () ->
    @each ->
      $(@).bind "keyup", $.size_to_fit
      $(@).bind "change", $.size_to_fit
      $.size_to_fit.apply(@)
