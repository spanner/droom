jQuery ($) ->
  $.headers = []
  
  $.params = (name) ->
    decodeURIComponent $.urlParam(name)
    
  class TableSort
    constructor: (element, options) ->
      @order = options.order
      @sort = options.sort
      @table = $(element)
      @body = @table.find('tbody')
      @_original_content = @body.children()
      @sort = $.params("sort")
      @order = $.params("order")
      @headers = @table.find('th a')
      $.each @headers, (i, header) =>
        header = new SortLink header, @
        $.headers.push header
      @activate()
      @table.bind "insert", @insert
      @resort @sort, @order
      if Modernizr.history
        $(window).bind 'popstate', @restoreState
      
    insert: () =>
      @body.fadeTo('fast', 0.2)
      $.ajax
        url: "/documents.js?sort=#{@sort}&order=#{@order}"
        dataType: "html"
        success: @insert_refresh
      
    insert_refresh: (data, textStatus, jqXHR) =>
      @clear()
      $(data).appendTo(@table)
      @body.fadeTo('fast', 1)
      @activate()
    
    resort: (sort, order) =>
      sort ?= "name"
      order ?= "ASC"
      @sort = sort
      @order = order
      console.log "resort", sort, order
      @get("/documents.js?sort=#{sort}&order=#{order}")
    
    get: (url) =>
      @body.fadeTo('fast', 0.2)
      $.ajax
        url: (url)
        dataType: "html"
        success: @refresh
    
    refresh: (data, textStatus, jqXHR) =>
      @clear()
      @saveState(data) if Modernizr.history
      $(data).appendTo(@table)
      @body.fadeTo('fast', 1)
      @activate()

    activate: () =>
      @body.find('a.popup').popup_remote_content()
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
        $(event.state.html).appendTo(@table)
        $.each $.headers, (i, header) =>
          header.check()
        @activate()
        

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
      if @_order == "ASC"
        @_link.attr('data-order', 'DESC')
        @_order = "DESC"
      else
        @_link.attr('data-order', 'ASC')
        @_order = "ASC"
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

  class Refresher
    constructor: (element) ->
      @_container = $(element)
      console.log @_container
      @_url = @_container.attr 'data-url'
      @_container.bind "insert", @insert
      
    insert: () =>
      console.log "insert"
      $.ajax @_url,
        dataType: "html"
        success: @replace
    
    replace: (data, textStatus, jqXHR) =>
      @_container.replaceWith(data, textStatus, jqXHR)
      
      
  $.fn.refresher = () ->
    @each ->
      new Refresher @
