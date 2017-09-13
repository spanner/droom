
## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Ed.Views.AssetInserter extends Ed.View
  template: "assets/inserter"
  tagName: "div"
  className: "ed-inserter"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"

  onRender: () =>
    @_p = null

  #TODO shouldn't we know about the holding editable so as to tell it about new assets?
  attendTo: ($el) =>
    @_target_el = $el
    @$el.appendTo $('body')
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    selection = @el.ownerDocument.getSelection()
    if !selection or selection.rangeCount is 0
      current = $(e.target)
    else
      range = selection.getRangeAt(0)
      current = $(range.commonAncestorContainer)
    @_p = current.closest('p')
    if @_p.length and @isBlank(@_p.text())
      @show(@_p)
    else
      @hide()

  toggleButtons: (e) =>
    e?.preventDefault()
    if @$el.hasClass('showing') then @$el.removeClass('showing') else @$el.addClass('showing')

  addImage: () =>
    @insert new Ed.Views.Image
      model: new Ed.Models.Image

  addVideo: () =>
    @insert new Ed.Views.Video
      model: new Ed.Models.Video

  addQuote: () =>
    @insert new Ed.Views.Quote
      model: new Ed.Models.Quote

  insert: (view) =>
    if @_p
      @_p.before view.el
      @_p.remove() if @isBlank(@_p.text())
    else
      @_target_el.append view.el
    view.render()
    view.focus?()
    @_target_el.trigger 'input'
    @hide()

  place: ($el) =>
    position = $el.offset()
    @$el.css
      top: position.top - 16
      left: position.left - 60

  show: () =>
    @place(@_p)
    @$el.show()
    @_target_el.parents('.scroller').on 'scroll', => @place(@_p)

  hide: () =>
    @$el.hide()
    @$el.removeClass('showing')
    @_target_el.parents('.scroller').off 'scroll'



## Asset styles
#
# All the assets get the same layout options, selected by buttons in this view.

class Ed.Views.AssetStyler extends Ed.View
  tagName: "div"
  className: "styler"
  template: "assets/styler"
  events:
    "click a.right": "setRight"
    "click a.left": "setLeft"
    "click a.full": "setFull"
    "click a.wide": "setWide"
    "click a.hero": "setHero"

  onRender: =>
    if @model
      @$el.show()
    else
      @$el.hide()

  setModel: (model) =>
    @model = model
    @render()

  setRight: () => @trigger "styled", "right"
  setLeft: () => @trigger "styled", "left"
  setFull: () => @trigger "styled", "full"
  setWide: () => @trigger "styled", "wide"
  setHero: () => @trigger "styled", "heroic"



class Ed.Views.ProgressBar extends Ed.View
  template: false
  tagName: "span"
  className: "ed-progress"
  
  bindings:
    ":el":
      observe: "progressing"
      visible: true
    ".label":
      observe: "progress"
      update: "progressLabel"

  initialize: () ->
    @_size = @options.size
    @_thickness = @options.thickness
    $.pg = @
    $.m = @model

  onRender: () =>
    @initProgress()
    @stickit() if @model
    @model?.on "change:progress", @showProgress

  setModel: (model) =>
    @model = model
    @render()

  initProgress: =>
    @$el.append('<div class="label"></div>')
    @$el.circleProgress
      size: @_size
      thickness: @_thickness
      fill:
        color: "rgba(255,255,255,0.9)"
      emptyFill: "rgba(255,255,255,0.2)"

  showProgress: (model, progress) =>
    @initProgress() unless @$el.data('circle-progress')
    if progress > 1
      @$el.fadeOut(1000)
    else
      @$el.show() unless @$el.is(':visible')
      @$el.circleProgress "value", progress

  progressLabel: ($el, progress, model, options) =>
    if progress > 1
      $el.text("Done")
    else if progress <= 0.99
      $el.text("#{progress * 100}%").removeClass('processing')
    else
      $el.html("please wait").addClass('processing')
