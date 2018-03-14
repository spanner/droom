# Base class with useful bits and pieces.

class Ed.View extends Backbone.Marionette.View
  template: false

  initialize: =>
    @subviews = []
    @beforeWrap()
    @wrap()
    @render()

  wrap: =>
    # each subclass should have its own way of lifting data from the DOM to populate a model.

  beforeWrap: =>
    @bindUIElements()
    # possibly with some dom manipulation

  onRender: =>
    @stickit()
    # _.defer -> balanceText('.balanced')

  onDestroy: =>
    subview.destroy() for subview in @subviews


  ## Binding helpers
  #
  untrue: (value) =>
    not value

  ifBlank: (value) =>
    not value?.trim()

  present: (value) =>
    not not value

  inBytes: (value) =>
    if value
      if value > 1048576
        mb = Math.floor(value / 10485.76) / 100
        "#{mb}MB"
      else
        kb = Math.floor(value / 1024)
        "#{kb}KB"
    else
      ""

  inPixels: (value=0) =>
    "#{value}px"

  inTime: (value=0) =>
    seconds = parseInt(value, 10)
    if seconds >= 3600
      minutes = Math.floor(seconds / 60)
      [Math.floor(minutes / 60), minutes % 60, seconds % 60].join(':')
    else
      [Math.floor(seconds / 60), seconds % 60].join(':')

  asPercentage: (value=0) =>
    "#{value}%"

  providerClass: (provider) =>
    "yt" if provider is "YouTube"

  ## Utilities

  isBlank: (string) =>
    if string
      /^\s*$/.test('' + string)
    else
      true

  containEvent: (e) =>
    e?.stopPropagation()
    e?.preventDefault()

  log: ->
    if _ed.logging() and console?.log?
      console.log "[#{@constructor.name}]", arguments...


class Ed.Views.CompositeView extends Backbone.Marionette.CompositeView

  initialize: =>
    @beforeWrap()
    @wrap()
    @render()

  wrap: =>
    # each subclass should have its own way of lifting data from the DOM to populate a collection.

  beforeWrap: =>
    @bindUIElements()
    # possibly with some dom manipulation



class Ed.Views.MenuView extends Backbone.Marionette.View

  onRender: =>
    @stickit() if @model

  toggleMenu: =>
    if @showing()
      @close()
    else
      @open()

  showing: =>
    @$el.hasClass('open')

  open: =>
    @$el.addClass('open')
    @ui.body.show()

  close: =>
    @_menu_view?.close()
    @ui.body.hide()
    @$el.removeClass('open')
