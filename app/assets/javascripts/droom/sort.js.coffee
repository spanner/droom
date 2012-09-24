jQuery ($) ->

  class TableSort
    constructor: (element, options) ->
      @order = options.order
      @sort = options.sort
      @table = $(element)
      @body = @table.find('tbody')
      @headers = @table.find('th a')
      $.each @headers, (i, header) =>
        new SortLink header, @
      @activate()
        
    resort: (sort, order) =>
      sort ?= "name"
      order ?= "asc"
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
      $(data).appendTo(@body)
      @activate()

    activate: () =>
      @body.find('a.popup').popup_remote_content()
      @body.find('.pagination').find('a').retable(@)
      @body.fadeTo('fast', 1)
      
    clear: () =>
      @body.children().remove()
      

  class SortLink
    constructor: (element, table) ->
      @table = table
      @_link = $(element)
      @_sort = @_link.attr("data-sort")
      @_order = null
      @_link.bind "click", @click
      if @table.sort == @_sort
        @_link.attr("data-order", @table.order)
      
    click: () =>
      @table.headers.removeAttr('data-order')
      if @_order == "asc"
        @_link.attr('data-order', 'DESC')
        @_order = "desc"
      else
        @_link.attr('data-order', 'ASC')
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
