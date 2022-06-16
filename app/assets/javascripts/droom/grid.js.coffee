$.fn.autoGrid = ->
  @each ->
    $(@).find('.gridbox').gridBox()

$.fn.gridBox = ->
  @each ->
    $el = $(@)
    row = 20
    space = 20
    sizer = ->
      contents = $el.find('.content')
      console.log "sizer!", contents, contents.outerHeight()
      rows_touched = Math.ceil(contents.outerHeight() / (row + space)) + 2
      $el.css "grid-row-end", "span #{rows_touched}"
      $el.addClass('ready')
    sizer()
    $el.find('img').on 'load', =>
      console.log "resizer!"
      sizer()


$.fn.highlight = ->
  if @offset()
    $('html,body').animate {scrollTop: @offset().top - 100}, 500
    @addClass('flash')
    @trigger 'expand'

$.fn.notice = ->
  @each ->
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
