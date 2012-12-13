jQuery ($) ->

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




  $.namespace "Droom", (target, top) ->
    target.TableSort = TableSort
