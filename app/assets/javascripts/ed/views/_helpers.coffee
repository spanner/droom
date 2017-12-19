## Asset-choosers
#
# The submenu for each asset picker is a chooser-list.
# These are small thumbnail galleries with add and import controls alongside.
#
class Ed.Views.ListedAsset extends Ed.View
  template: "ed/listed"
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
  template: "ed/none"
  tagName: "li"
  className: "empty"


class Ed.Views.AssetsList extends Backbone.Marionette.CompositeView
  template: "ed/list"
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


## Toolbar
#
# Attaches an editing toolbar to a DOM element.
#
class Ed.Views.Toolbar extends Ed.View
  template: false
  className: "ed-toolbar"

  initialize: (opts={}) =>
    @target_el = opts.target

  onRender: () =>
    @_toolbar ?= new MediumEditor @target_el,
      placeholder: false
      autoLink: true
      imageDragging: false
      anchor:
        customClassOption: null
        customClassOptionText: 'Button'
        linkValidation: false
        placeholderText: 'URL...'
        targetCheckbox: false
      anchorPreview: false
      paste:
        forcePlainText: false
        cleanPastedHTML: true
        cleanReplacements: []
        cleanAttrs: ['class', 'style', 'dir']
        cleanTags: ['meta']
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: false
        buttons: [
          name: 'bold'
          contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
        ,
          name: 'italic'
          contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
        ,
          name: 'anchor'
          contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
        ,
          name: 'h2'
          contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
        ,
          name: 'h3'
          contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
        ]


## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Ed.Views.AssetInserter extends Ed.View
  template: "ed/inserter"
  tagName: "div"
  className: "ed-inserter"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"
    "click a.button": "addButton"
    "click a.blocks": "addBlocks"

  onRender: () =>
    @_p = null

  #TODO shouldn't we know about the holding editable so as to tell it about new assets?
  # and also todo: please can we just render this with no special calls?
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
    if @_p.length and @isBlank(@_p.text())# and not @_p.is(':first-child')
      @show(@_p)
    else
      @hide()

  toggleButtons: (e) =>
    e?.preventDefault()
    if @$el.hasClass('showing')
      @trigger 'contract'
      @$el.removeClass('showing')
    else
      @trigger 'expand'
      @$el.addClass('showing')

  addImage: =>
    @insert new Ed.Views.Image

  addVideo: =>
    @insert new Ed.Views.Video

  addQuote: =>
    @insert new Ed.Views.Quote

  addButton: =>
    @insert new Ed.Views.Button

  addBlocks: =>
    @insert new Ed.Views.Blocks

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
  template: "ed/styler"
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


class Ed.Views.ImageWeighter extends Ed.Views.MenuView
  tagName: "div"
  className: "weighter"
  template: "ed/weighter"

  ui:
    head: ".menu-head"
    body: ".menu-body"

  events:
    "click @ui.head": "toggleMenu"

  bindings: 
    "input.weight": "main_image_weighting"




## Asset-pickers
#
# These menus are embedded in the asset view. They select from an asset collection to
# set the model in the asset view, with the option to upload or import new items.
#

class Ed.Views.AssetPicker extends Ed.Views.MenuView
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

  open: =>
    @ui.body.show()
    unless @_menu_view
      @_menu_view = new Ed.Views.AssetsList
        collection: @collection
        title: @getOption('title')
      @ui.body.append @_menu_view.el
      @_menu_view.render()
      @_menu_view.on "select", @select
    @_menu_view.open()
    @$el.addClass('open')

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

  containEvent: (e) =>
    e?.stopPropagation()


class Ed.Views.AssetRemover extends Backbone.Marionette.View
  template: "ed/remover"
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
  template: "ed/image_picker"
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
  template: "ed/main_image_picker"
  title: "Images"


class Ed.Views.VideoPicker extends Ed.Views.AssetPicker
  template: "ed/video_picker"
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
  template: "ed/quote_picker"
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
