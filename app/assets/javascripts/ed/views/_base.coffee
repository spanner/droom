# Base class with useful bits and pieces.

class Ed.View extends Backbone.Marionette.View
  template: false

  initialize: =>
    @subviews = []
    @beforeWrap()
    @wrap()
    @render()

  # each subclass should have its own way of lifting data from the DOM to populate a model.
  wrap: =>
    false

  beforeWrap: =>
    @bindUIElements()
    # possibly with some dom manipulation

  onRender: =>
    @stickit() if @model
    # _.defer -> balanceText('.balanced')

  onDestroy: =>
    subview.destroy() for subview in @subviews


  ## Binding helpers
  #
  untrue: (value) =>
    not value

  thisOrThat: ([thing, other_thing]=[]) =>
    @log "thisOrThat", thing, other_thing
    thing or other_thing or ""

  thisButNotThat:  ([thing, other_thing]=[]) =>
    @log "thisButNotThat", thing, other_thing
    !!thing and not !!other_thing

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


  ## style-binding helpers
  #
  styleColor: (color) =>
    "color: #{color}" if color

  styleBackgroundColor: (color) =>
    "background-color: #{color}" if color

  styleBackgroundImage: ([url, data]=[]) =>
    debugger
    url ||= data
    if url
      "background-image: url('#{url}')"
    else 
      ""

  styleBackgroundImageAndPosition: ([url, weighting]=[]) =>
    weighting ?= 'center center'
    "background-image: url('#{url}'); background-position: #{weighting}"

  urlAtSize: (url) =>
    @model.get("#{@_size}_url") ? url

  styleBackgroundAtSize: (url) =>
    if url
      "background-image: url('#{@urlAtSize(url)}')"


  ## Contenteditable helpers

  ensureP: (e) =>
    el = e.target
    if el.innerHTML is ""
      el.style.minHeight = el.offsetHeight + 'px'
      p = document.createElement('p')
      p.innerHTML = "&#8203;"
      el.appendChild p

  clearP: (e) =>
    el = e.target
    content = el.innerHTML
    el.innerHTML = "" if content is "<p>&#8203;</p>" or content is "<p><br></p>" or content is "<p></p>" or content is "<p>​</p>"  # there's a zwsp in that last string


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
    _ed.log "[#{@constructor.name}]", arguments...

  complain: ->
    _ed.complain arguments...

  confirm: ->
    _ed.confirm arguments...


## Collection Views
#
# Adds some conventional lifecycle and useful bindings to our various list and selection views.
#
class Ed.CollectionView extends Backbone.Marionette.CollectionView

  initialize: =>
    @render()

  log: ->
    _cms.log "[#{@constructor.name}]", arguments...


class Ed.CompositeView extends Backbone.Marionette.CompositeView

  initialize: =>
    @beforeWrap()
    @wrap()
    @render()

  wrap: =>
    # each subclass should have its own way of lifting data from the DOM to populate a collection.

  beforeWrap: =>
    # ...possibly with some dom manipulation
    @bindUIElements()



# The menu view has a head and a toggled body.
# Examples include the image and video pickers.
#
class Ed.Views.MenuView extends Ed.View

  ui:
    head: ".menu-head"
    body: ".menu-body"
    closer: "a.close"

  events:
    "click @ui.head": "toggleMenu"
    "click @ui.closer": "close"

  toggleMenu: (e) =>
    e?.preventDefault()
    if @showing() then @close() else @open()

  showing: =>
    @$el.hasClass('open')

  open: (e) =>
    e?.preventDefault()
    @$el.addClass('open')
    @triggerMethod 'open'
    @trigger 'opened'

  close: (e) =>
    e?.preventDefault()
    @_menu_view?.close()
    @$el.removeClass('open')
    @triggerMethod 'close'
    @trigger 'closed'
