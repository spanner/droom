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
      @_selector = @_container.attr("data-alternate")
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


  # The *folder* action is just a display convention that shows and hides the contents of a folder
  # when its link is clicked. It should probably become a subclass of the generic toggle mechanism and benefit from its persistence.
      
  $.fn.folder = ->
    @each ->
      new Folder(@)
      
  class Folder
    constructor: (element) ->
      @_container = $(element)
      @_list = @_container.find('ul.filing')
      @_container.find('a.folder').click @toggle
      @set()
      
    set: (e) =>
      e.preventDefault() if e
      if @_container.hasClass('open') then @show() else @hide()

    toggle: (e) =>
      e.preventDefault() if e
      if @_container.hasClass('open') then @hide() else @show()

    show: (e) =>
      e.preventDefault() if e
      @_container.addClass('open')
      @_list.stop().slideDown()
      
    hide: (e) =>
      e.preventDefault() if e
      @_container.removeClass('open')
      @_list.stop().slideUp()

  # The *twister* is yet another show/hider, not currently in use since the library view has gone over to folders.

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




  # A captive form submits via an ajax request and pushes its results into the present page in the place 
  # designated by its 'replacing' attribute.
  #
  # If options['fast'] is true, the form will submit on every change to a text, radio or checkbox input.
  #
  #todo: This is very old now. Tidy it up with a more standard action structure, and fewer options.

  $.fn.captive = (options) ->
    options = $.extend(
      replacing: "#results"
      clearing: null
    , options)
    @each ->
      new CaptiveForm @, options
    @

  class CaptiveForm
    constructor: (element, opts) ->
      @_form = $(element)
      @_prompt = @_form.find("input[type=\"text\"]")
      @_options = $.extend {}, opts
      @_request = null
      @_placed_content = null
      @_original_content = $(@_options.replacing)
      @_form.remote
        on_submit: @prepare
        on_cancel: @cancel
        on_complete: @capture
        
      if @_options.fast
        @_form.find("input[type=\"text\"]").keyup @keyed
        @_form.find("input[type=\"radio\"]").click @submit
        @_form.find("input[type=\"checkbox\"]").click @submit
      
    keyed: (e) =>
      k = e.which
      if (k >= 32 and k <= 165) or k == 8
        if @_prompt.val() == "" then @revert() else @update()
    
    submit: (e) =>
      e.preventDefault() if e
      @_form.submit()
      
    prepare: (xhr, settings) =>
      $(@_options.replacing).fadeTo "fast", 0.2
      @_request.abort() if @_request
      @_request = xhr
    
    capture: (data, status, xhr) =>
      @display(data)
      @_request = null
    
    display: (results) =>
      replacement = $(results)
      replacement.find('a.cancel').click @revert
      @_placed_content?.remove()
      @_original_content?.hide()
      @_original_content?.before(replacement)
      $(@_options.clearing).val("")
      @_placed_content = replacement
    
    revert: (e) =>
      e.preventDefault() if e
      @_placed_content?.remove()
      @_original_content?.fadeTo "fast", 1
      @_prompt.val("")
      @saveState()

  # The suggestions form is a fast captive with history support based on a single prompt field.
  #
  $.fn.suggestion_form = (options) ->
    options = $.extend(
      replacing: "#search_results"
      clearing: null
    , options)
    @each ->
      new SuggestionForm @, options
    @
  
  class SuggestionForm extends CaptiveForm
    constructor: (element, opts) ->
      super
      @_prompt = @_form.find("input[type=\"text\"]")
      # if @_original_term = decodeURIComponent $.urlParam("q") if $.urlParam("q")
        # @_prompt.val(@_original_term)
        # @submit() unless @_prompt.val() is ""
      if Modernizr.history
        $(window).bind 'popstate', @restoreState

    capture: (data, status, xhr) =>
      @saveState(data) if Modernizr.history
      super

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
      history.pushState state, "Search results", url
    
    restoreState: (e) =>
      event = e.originalEvent
      if event.state? && event.state.html?
        @display event.state.html
        @_prompt.val(event.state.term)




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
      @search_box.on "keyup", @submit

    submit: =>
      $.ajax
        url: "#{@form.attr('action')}?term=#{@search_box.val()}"
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



  class Filter
    constructor: (element) ->
      @_container = $(element)
      @_defilter = $('<a href="#" class="defilter" />').insertAfter(@_container)
      @_affected = @_container.attr('data-affected')
      @setDefilter()
      @_container.bind "keyup", @setQuery
      @_defilter.bind "click", @clearQuery
      # @announce()
      console.log "Filter", @_container.get(0)

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

  $.fn.search_filter = () ->
    @each ->
      new Filter @
    @


  class TableSort
    constructor: (element, opts) ->
      @table = $(element)
      @url ?= @table.attr("data-url") ? "/documents"
      @_affected = $(@table.attr('data-affected'))
      @query = ""
      @sort = null
      @order = null
      @_request = null
      @_cache = {}
      @_request = null
      @_original_content = @table.clone()
      @activate()
      $(window).bind 'popstate', @restoreState if Modernizr.history
      
    wait: () =>
      @table.fadeTo('fast', 0.2)
    
    unWait: () =>
      @table.fadeTo('fast', 1)
    
    setQuery: (e, q) =>
      @query = q
      @get()
      
    get: (url) =>
      url ?= @url + '?sort=' + encodeURIComponent(@sort) + '&order=' + encodeURIComponent(@order)+ '&q=' + encodeURIComponent(@query)
      @_request.abort() if @_request
      @wait()
      if @_cache[url]
        @display @_cache[url], url
      else
        @_request = $.ajax
          url: url
          dataType: "html"
          success: (data) =>
            @_cache[url] = data
            @display(data, url)

    display: (data, url) =>
      @_affected.trigger('refresh', @query)
      replacement = $(data).insertAfter(@table).hide()
      @table.remove()
      @table = replacement
      @table.children().activate()
      @table.fadeTo('fast', 1)
      @activate()
      @saveState(data, url) if url and Modernizr.history

    activate: () =>
      @table.refresher()
      @table.bind "refresh", @get
      @table.bind "filter", @setQuery
      @sort ?= @table.attr("data-sort")
      @order ?= @table.attr("data-order")
      @table.find('a.sorter, .pagination a').click (e) =>
        e.preventDefault() if e
        if url = $(e.target).attr('href')
          @get(url)
    
    saveState: (data, url) =>
      state = 
        html: data
      history.pushState state, "Reviewers", url.replace(".js", "")  #hack!

    restoreState: (e) =>
      event = e.originalEvent
      @display(event.state.html) if event.state? && event.state.html?


  $.fn.table_sort = (options) ->
    @each ->
      new TableSort @, options
    @
