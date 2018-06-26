$.fn.autoGrid = ->
  @each ->
    $(@).find('.gridbox').gridBox()

$.fn.gridBox = ->
  @each ->
    $el = $(@)
    contents = $el.find('.content')
    row = 20
    space = 20
    rows_touched = Math.ceil(contents.outerHeight() / (row + space))
    $el.css "grid-row-end", "span #{rows_touched}"
    $el.addClass('ready')

$.fn.highlight = ->
  if @offset()
    $('html,body').animate {scrollTop: @offset().top - 100}, 500
    @addClass('flash')
    @trigger 'expand'

$.fn.notice = ->
  @each ->
    console.log "notice!", @
    $(@).gridBox()
    new Notice(@)

class Notice
  constructor: (element) ->
    @_container = $(element)
    @_container.gridBox()
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

  reflow: =>
    @_container.gridBox()

  refresh: (e, new_container) =>
    @_container = $(new_container)
    @_container.on 'refreshed', @refresh
    @_expander = @_container.find('a.reveal')
