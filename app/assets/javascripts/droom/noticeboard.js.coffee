$.fn.waterfallify = ->
  @each ->
    $el = $(@)
    waterfall = $el.waterfall
      defaultContainerWidth: 900
      colMinWidth: 300
      autoresize: true
    $(window).on 'resize', -> waterfall.reflow()
    $(window).on 'load', -> waterfall.reflow()
    $el.find('.notice').notice(waterfall)
    $(document.location.hash).highlight()
    $el.on 'refreshed', ->
      _.defer ->
        $('#noticeboard').waterfallify()


$.fn.highlight = ->
  if @offset()
    $('html,body').animate {scrollTop: @offset().top - 100}, 500
    @addClass('flash')
    @trigger 'expand'

$.fn.notice = (waterfall) ->
  @each ->
    new Notice(@, waterfall)


class Notice
  constructor: (element, waterfall) ->
    @_container = $(element)
    @_waterfall = waterfall
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
    @reflow()

  reflow: (e) =>
    if @_container.index() == 0
      @_container.data 'span', 2
    @_waterfall?.reflow()

