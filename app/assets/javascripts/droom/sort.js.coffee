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
      @sort_table(@order)
        
    sort_table: (order) =>
      sort = if @sort then @sort else "created_at"
      order = if order then order else "DESC"
      $.ajax
        url: "/documents.js?sort=#{sort}&order=#{order}"
        dataType: "html"
        success: (data) =>
          @prepare()
          @append data
        
    append: (data, textStatus, jqXHR) =>
      tbody = @body.append data
      tbody.popup_remote_content()
    
    prepare: () =>
      @body.children().remove()
      
      
  class SortLink
    constructor: (element, table) ->
      @table = table
      @_link = $(element)
      @_sort = @_link.attr("data-sort")
      @_link.bind "click", @click
      if @table.sort == @_sort
        @_link.attr("data-order", @table.order)
      
    click: () =>
      @table.sort = @_sort
      @table.headers.removeAttr('data-order')
      if @_order == "DESC"
        @_link.attr('data-order', 'ASC')
        @_order = "ASC"
      else
        @_link.attr('data-order', 'DESC')
        @_order = "DESC"
      @table.sort_table(@_order)
      

  $.fn.table_sort = (options) ->
    @each ->
      new TableSort @, options
    @
