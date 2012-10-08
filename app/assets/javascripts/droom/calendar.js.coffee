jQuery ($) ->

  class Calendar
    constructor: (element, options) ->
      @_container = $(element)
      @_scroller = @_container.find('.scroller')
      @_table = null
      @_cache = {}
      @_month = null
      @_year = null
      @_request = null
      @_incoming = {}
      @_width = @_container.width()
      $.calendar = @
      @_container.bind "refresh", @refresh_in_place
      @init()

    init: () =>
      @_table = @_container.find('table')
      @_month = parseInt(@_table.attr('data-month'), 10)
      @_year = parseInt(@_table.attr('data-year'), 10)
      @cache(@_year, @_month, @_table)
      @_table.find('a.next, a.previous').calendar_changer()
      @_table.find('a.day').day_search()
      @_table.find('a.month').month_search()
      
    cache: (year, month, table) =>
      @_cache[year] ?= {}
      @_cache[year][month] ?= table
    
    cached:  (year, month) =>
      @_cache[year] ?= {}
      @_cache[year][month]
    
    refresh_in_place: () =>
      @_request = $.ajax
        type: "GET"
        dataType: "html"
        url: "/events/calendar.js?month=#{encodeURIComponent(@_month)}&year=#{encodeURIComponent(@_year)}"
        success: @update_quietly
      
    update_quietly: (response) =>
      @_container.find('a').removeClass('waiting')
      @_scroller.find('table').remove()
      @_scroller.append(response)
      @init()
      
    show: (year, month) =>
      if cached = @cached(year, month)
        @update(cached, year, month)
      else
        @_request = $.ajax
          type: "GET"
          dataType: "html"
          url: "/events/calendar.js?month=#{encodeURIComponent(month)}&year=#{encodeURIComponent(year)}"
          success: (response) =>
            @update(response, year, month)
    
    update: (response, year, month) =>
      @_container.find('a').removeClass('waiting')
      direction = "left" if ((year * 12) + month) > ((@_year * 12) + @_month)
      @sweep response, direction
    
    sweep: (table, direction) =>
      old = @_scroller.find('table')
      if direction == 'left'
        @_scroller.append(table)
        @_container.animate {scrollLeft: @_width}, 'fast', () =>
          old.remove()
          @_container.scrollLeft(0)
          @init()
      else
        @_scroller.prepend(table)
        @_container.scrollLeft(@_width).animate {scrollLeft: 0}, 'fast', () =>
          old.remove()
          @init()
    
    monthName: () =>
      Kalendae.moment.months[@_month-1]
      
    searchForm: =>
      @_form ?= $('#searchform')
      
    searchFor: (day) =>
      if day?
        @search("#{@monthName()} #{day}, #{@_year}")
      else
        @search("#{@monthName()} #{@_year}")

    search: (term) =>
      @searchForm().find('input#term').val(term)
      @searchForm().submit()
      

  $.fn.calendar = ->
    @each ->
      new Calendar(@)
    @
    
  $.fn.calendar_changer = ->
    @click (e) ->
      e.preventDefault() if e
      link = $(@)
      year = parseInt(link.attr('data-year'), 10)
      month = parseInt(link.attr('data-month'), 10)
      link.addClass('waiting')
      $.calendar?.show(year, month)
    @

  $.fn.day_search = ->
    @click (e) ->
      e.preventDefault() if e
      $.calendar?.searchFor($(@).text())
      
  $.fn.month_search = ->
    @click (e) ->
      e.preventDefault() if e
      $.calendar?.searchFor()
  
      
      
