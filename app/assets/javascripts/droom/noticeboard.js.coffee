$.fn.autoGrid = ->
  @each ->
    $(@).find('.gridbox').gridBox()

$.fn.gridBox = ->
  @each ->
    $el = $(@)
    contents = $el.find('.content')
    row = 20
    space = 20
    rows_touched = Math.ceil((contents.outerHeight() + row) / (row + space))
    $el.css "grid-row-end", "span #{rows_touched}"
    $el.addClass('ready')

$.fn.noticeboard = ->
  @each ->
    $el = $(@)
    $el.autoGrid()
    $el.find('.notice').notice()
    $(document.location.hash).highlight()

$.fn.highlight = ->
  if @offset()
    $('html,body').animate {scrollTop: @offset().top - 100}, 500
    @addClass('flash')
    @trigger 'expand'


$.fn.notice = ->
  @each ->
    new Notice(@)


class Notice
  constructor: (element) ->
    @_container = $(element)
    @_container.on 'refreshed', @refresh
    @_expander = @_container.find('a.reveal')
    if @_expander.length
      @_expander.bind 'click', @toggleExpansion
    else
      @_container.addClass('unexpandable')
    @_container.on 'expand', @expand

  expand: =>
    @_container.addClass('expanded')
    @reflow()

  toggleExpansion: (e) =>
    @_container.toggleClass('expanded')
    @reflow()

  refresh: (e, new_container) =>
    @_container = $(new_container)
    @_container.on 'refreshed', @refresh
    @_expander = @_container.find('a.reveal')
