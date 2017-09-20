## Asset-choosers
#
# The submenu for each asset picker is a chooser-list.
# These are small thumbnail galleries with add and import controls alongside.
#
class Ed.Views.ListedAsset extends Ed.View
  template: "assets/listed"
  tagName: "li"
  className: "asset"

  ui:
    img: 'img'

  events:
    "click a.delete": "deleteModel"
    "click a.preview": "selectMe"

  bindings:
    "a.preview":
      attributes: [
        name: 'style'
        observe: 'icon_url'
        onGet: "backgroundUrl"
      ,
        name: "class"
        observe: "provider"
        onGet: "providerClass"
      ,
        name: "title"
        observe: "title"
      ]
    ".file_size":
      observe: "file_size"
      onGet: "inBytes"
    ".width":
      observe: "width"
      onGet: "inPixels"
    ".height":
      observe: "height"
      onGet: "inPixels"
    ".duration":
      observe: "duration"
      onGet: "inTime"

  onRender: =>
    @stickit()
    @_progress = new Ed.Views.ProgressBar
      model: @model
      size: 40
      thickness: 10
    @_progress.$el.appendTo @$el
    @_progress.render()

  deleteModel: (e) =>
    e?.preventDefault()
    @model.remove()

  selectMe: (e) =>
    e?.preventDefault?()
    @trigger 'select', @model

  backgroundUrl: (url) =>
    if url
      "background-image: url('#{url}')"
    else
      ""


class Ed.Views.NoAsset extends Ed.View
  template: "assets/none"
  tagName: "li"
  className: "empty"


class Ed.Views.AssetsList extends Backbone.Marionette.CompositeView
  template: "assets/list"
  childViewContainer: "ul.ed-assets"
  childView: Ed.Views.ListedAsset
  emptyView: Ed.Views.NoAsset

  events:
    "click a.import": "importAsset"
    "click a.next": "nextPage"
    "click a.prev": "prevPage"

  childViewEvents:
    'select': 'select'

  ui:
    'heading': 'span.heading'
    'search_field': 'input.q'
    'prev_button': 'a.prev'
    'next_button': 'a.next'
    'import_field': 'input.remote_url'
    'import_button': 'a.import'

  initialize: (opts={}) =>
    @_q = ""
    @_p = 1
    @_title = opts.title ? "Assets"
    @_master_collection = @collection.clone()
    @_master_collection.on "reset", @selectAssets
    @_filterSoon = _.debounce @selectAssets, 250
    $.al = @

  onRender: =>
    @ui.heading.text @_title
    @ui.search_field.on 'input', @_filterSoon
    @selectAssets()

  # passed through to the picker.
  #
  select: (model) =>
    @trigger 'select', model

  open: =>
    @$el.slideDown 'fast'

  close: =>
    @$el.slideUp 'fast'

  closeAndRemove: (callback) =>
    @$el.slideUp 'fast', =>
      @remove()
      callback?()

  importAsset: =>
    if remote_url = @ui.import_field.val()
      @ui.import_button.addClass('waiting')
      imported = @collection.add
        remote_url: remote_url
      imported.save().done =>
        @ui.import_button.removeClass('waiting')
        @ui.import_field.val("")
        @trigger 'selected', imported

  selectAssets: (e, q) =>
    first = (@_p - 1) * 20
    last = first + 20
    if q = @ui.search_field.val()
      re = new RegExp(q, 'i')
      matches = @_master_collection.select (image) ->
        re.test(image.get('title')) or re.test(image.get('caption'))
    else
      matches = @_master_collection.toArray()

    @collection.reset matches.slice(first,last)

    total = matches.length
    if total > last
      @ui.next_button.removeClass('inactive')
    else
      @ui.next_button.addClass('inactive')
    if first == 0
      @ui.prev_button.addClass('inactive')
    else
      @ui.prev_button.removeClass('inactive')

  nextPage: =>
    @_p = @_p + 1
    @selectAssets()

  prevPage: =>
    @_p = @_p - 1
    @_p = 1 if @_p < 1
    @selectAssets()


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
      # @_p.remove() if @isBlank(@_p.text())
    else
      @_target_el.append view.el
      @_target_el.append $("<p />")
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

  setRight: => @trigger "styled", "right"
  setLeft: => @trigger "styled", "left"
  setFull: => @trigger "styled", "full"
  setWide: => @trigger "styled", "wide"


## Asset-pickers
#
# These menus are embedded in the asset view. They select from an asset collection to
# set the model in the asset view, with the option to upload or import new items.
#
class Ed.Views.AssetPicker extends Backbone.Marionette.View
  tagName: "div"
  className: "picker"
  menuView: Ed.Views.AssetsList

  ui:
    head: ".menu-head"
    body: ".menu-body"
    label: "label"
    filefield: 'input[type="file"]'

  events:
    "click @ui.head": "toggleMenu"
    "click @ui.filefield": "containEvent" # always artificial

  onRender: =>
    @ui.label.on "click", @close
    @ui.filefield.on 'change', @getPickedFile

  toggleMenu: =>
    if @showing()
      @close()
    else
      @open()

  showing: =>
    @$el.hasClass('open')

  open: =>
    unless @_menu_view
      @_menu_view = new Ed.Views.AssetsList
        collection: @collection
        title: @getOption('title')
      @ui.body.append @_menu_view.el
      @_menu_view.render()
      @_menu_view.on "select", @select
    @_menu_view.open()
    @$el.addClass('open')
    @$el.parents('.slide, figure').addClass('hold')

  close: =>
    @_menu_view?.close()
    @$el.removeClass('open')
    @$el.parents('.slide, figure').removeClass('hold')

  # passed through again to reach the Asset view.
  select: (model) =>
    @close()
    @trigger "select", model

  pickFile: (e) =>
    console.log "pickFile", e.target or e.originalEvent.target
    @ui.filefield.click()

  getPickedFile: (e) =>
    if files = @ui.filefield[0].files
      @readLocalFile files[0]

  readLocalFile: (file) =>
    if file?
      reader = new FileReader()
      reader.onloadend = => 
        @createModel reader.result, file
      reader.readAsDataURL(file)

  setWeighting: (e) =>
    e?.preventDefault()

  containEvent: (e) =>
    e?.stopPropagation()


class Ed.Views.AssetRemover extends Backbone.Marionette.View
  template: "assets/remover"
  className: "remover"

  ui:
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  show: =>
    @$el.show()

  hide: =>
    @$el.hide()

class Ed.Views.ImagePicker extends Ed.Views.AssetPicker
  template: "assets/image_picker"
  title: "Images"

  initialize: (data, options={}) ->
    @collection ?= _ed.images
    super

  createModel: (data, file) =>
    model = @collection.add
      file: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model


class Ed.Views.MainImagePicker extends Ed.Views.ImagePicker
  template: "assets/main_image_picker"
  title: "Images"


class Ed.Views.VideoPicker extends Ed.Views.AssetPicker
  template: "assets/video_picker"
  title: "Videos"

  initialize: ->
    @collection ?= _ed.videos
    super

  createModel: (data, file) =>
    model = @collection.unshift
      file: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @select(model)
    model.save().done =>
      @trigger "create", model


class Ed.Views.QuotePicker extends Ed.Views.AssetPicker
  template: "assets/quote_picker"
  title: "Quotes"


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
