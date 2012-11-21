jQuery ($) ->
  $.headers = []
  
  $.params = (name) ->
    decodeURIComponent $.urlParam(name)
    
  class TableSort
    constructor: (element, opts) ->
      @table = $(element)
      @body = @table.find('tbody')
      @search = $('input#q')
      
      @options = $.extend {}, opts
      @options.url ?= @body.attr("data-url") ? "/documents.js"
      @options.sort ?= @table.attr("data-sort") ? "created"
      @options.order ?= @table.attr("data-order") ? "desc"

      @sort = $.params("sort") ? @options.sort
      @order = $.params("order") ? @options.order
      @query = ""
      
      @headers = @table.find('th a.sorter')
      $.each @headers, (i, header) =>
        header = new SortLink header, @
        $.headers.push header
      
      @table.bind "refresh", @update
      @search.bind "keyup", @setQuery
      
      @_original_content = @body.children()
      if Modernizr.history
        $(window).bind 'popstate', @restoreState
    
    resort: (sort, order) =>
      sort ?= "name"
      order ?= "asc"
      @sort = sort
      @order = order
      @get("#{@options.url}?sort=#{sort}&order=#{order}&q=#{@query}")
      
    update: () =>
      @body.fadeTo('fast', 0.2)
      $.ajax
        url: "#{@options.url}?sort=#{@sort}&order=#{@order}&q=#{@query}"
        dataType: "html"
        success: @display

    get: (url) =>
      @body.fadeTo('fast', 0.2)
      $.ajax
        url: (url)
        dataType: "html"
        success: @refresh

    refresh: (data, textStatus, jqXHR) =>
      @clear()
      @saveState(data) if Modernizr.history
      @display(data)
      
    display: (data) =>
      replacement = $(data)
      @body.after(replacement)
      @body.remove()
      @body = replacement
      @body.fadeTo('fast', 1)
      @body.activate()
      @activate()

    activate: () =>
      @body.activate()
      @body.find('.pagination').find('a').retable(@)
      @body.refresher()
      
    clear: () =>
      @body.children().remove()
      
    saveState: (results) =>
      url = window.location.pathname + '?sort=' + encodeURIComponent(@sort) + '&order=' + encodeURIComponent(@order)
      state = 
        html: results
        sort: @sort
        order: @order
      history.pushState state, "New page title", url

    restoreState: (e) =>
      event = e.originalEvent
      if event.state? && event.state.html?
        @clear()
        @order = event.state.order
        @sort = event.state.sort
        @display(event.state.html)
        $.each $.headers, (i, header) =>
          header.check()

    setQuery: (e) =>
      kc = e.which
      console.log "setQuery", kc
      
      #   delete,     backspace,    alphanumerics,    number pad,        punctuation
      if (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
        @query = @search.val()
        @update()

      

  class SortLink
    constructor: (element, table) ->
      @table = table
      @_link = $(element)
      @_sort = @_link.attr("data-sort")
      @_link.bind "click", @click
      @check()
      @_order = @_link.attr("data-order")
      
    check: () =>
      if @table.sort == @_sort
        @table.headers.removeAttr('data-order')
        @_link.attr("data-order", @table.order)
      
    click: (e) =>
      e.preventDefault()
      @table.headers.removeAttr('data-order')
      if @_order == "asc"
        @_link.attr('data-order', 'desc')
        @_order = "desc"
      else
        @_link.attr('data-order', 'asc')
        @_order = "asc"
      @table.resort(@_sort, @_order)
      

  $.fn.table_sort = (options) ->
    @each ->
      new TableSort @, options
    @

  $.fn.retable = (table) ->
    @click (e) ->
      e.preventDefault() if e
      url = $(@).attr('href')
      table.get(url)
    @



