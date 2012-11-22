jQuery ($) ->
  $.headers = []
  
  $.params = (name) ->
    decodeURIComponent $.urlParam(name)
    
  class TableSort
    constructor: (element, opts) ->
      @table = $(element)
      @search = $('input#q')
      
      @options = $.extend {}, opts
      @options.url ?= @table.attr("data-url") ? "/documents"
      @options.sort ?= @table.attr("data-sort")
      @options.order ?= @table.attr("data-order")

      @sort = $.params("sort") ? @options.sort
      @order = $.params("order") ? @options.order
      @query = ""
      
      @table.bind "refresh", @get
      @search.bind "keyup", @setQuery
      
      @_original_content = @table.clone()
      if Modernizr.history
        $(window).bind 'popstate', @restoreState

      @activate()
      $.sorter = @
      
    wait: () =>
      @table.fadeTo('fast', 0.2)
    
    unWait: () =>
      @table.fadeTo('fast', 1)
      
    get: (url) =>
      @wait()
      $.ajax
        url: url
        dataType: "html"
        success: (data) =>
          @saveState(data, url) if Modernizr.history
          @display(data)

    display: (data) =>
      replacement = $(data).insertAfter(@table).hide()
      @table.remove()
      @table = replacement
      @table.activate().fadeTo('fast', 1)
      @activate()

    activate: () =>
      @table.refresher()
      @table.find('a.sorter, .pagination a').click (e) =>
        e.preventDefault() if e
        if url = $(e.target).attr('href')
          @get(url)

    setQuery: (e) =>
      kc = e.which
      #   delete,     backspace,    alphanumerics,    number pad,        punctuation
      if (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
        @query = @search.val()
        @get()
    
    saveState: (data, url) =>
      console.log "saveState", url
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




