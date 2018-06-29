## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Ed.Views.AssetInserter extends Ed.View
  template: "inserter"
  tagName: "div"
  className: "ed-inserter"

  ui:
    adders: "a.add"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"
    "click a.button": "addButton"
    "click a.blocks": "addBlocks"

  onRender: () =>
    @_p = null
    permitted_insertions = _ed.config('insertions')
    @ui.adders.each (i, el) =>
      $el = $(el)
      $el.hide() if permitted_insertions.indexOf($el.data('insert')) is -1

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
      top: position.top - 6
      left: position.left - 36

  show: () =>
    @place(@_p)
    @$el.show()
    @_target_el.parents('.scroller').on 'scroll', => @place(@_p)

  hide: () =>
    @$el.hide()
    @$el.removeClass('showing')
    @_target_el.parents('.scroller').off 'scroll'



## Asset editors
#
# Wrap around an embedded asset to present controls for editing or replacing it.
# The editor is responsible for adding pickers, stylers, importers and so on.
# We also catch some events here and pass them on, so as to present a broad target,
# including click to select and drop to upload. 
#
class Ed.Views.AssetEditor extends Ed.View
  defaultSize: "full"
  stylerView: "AssetStyler"
  importerView: "AssetImporter"
  uploaderView: "AssetUploader"

  ui:
    catcher: ".ed-dropmask"
    buttons: ".ed-buttons"
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  events:
    "click @ui.catcher": "closeHelpers"
    "dragenter @ui.catcher": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"

  initialize: (opts={}) =>
    @_size ?= _.result @, 'defaultSize'
    super

  onRender: =>
    @$el.attr('data-ed', true)
    @addHelpers()

  addHelpers: =>
    if uploader_view_class_name = @getOption('uploaderView')
      if uploader_view_class = Ed.Views[uploader_view_class_name]
        @_uploader = new uploader_view_class
          collection: @collection
        @_uploader.$el.appendTo @ui.buttons
        @_uploader.render()
        @_uploader.on "select", @setModel
        @_uploader.on "create", @update
        @_uploader.on "pick", => @closeHelpers()

    if importer_view_class_name = @getOption('importerView')
      if importer_view_class = Ed.Views[importer_view_class_name]
        @_importer = new importer_view_class
          collection: @collection
        @_importer.$el.appendTo @ui.buttons
        @_importer.render()
        @_importer.on "select", @setModel
        @_importer.on "create", @update
        @_importer.on "open", => @closeOtherHelpers(@_importer)

    if picker_view_class_name = @getOption('pickerView')
      if picker_view_class = Ed.Views[picker_view_class_name ]
        @_picker = new picker_view_class
          collection: @collection
        @_picker.$el.appendTo @ui.buttons
        @_picker.render()
        @_picker.on "select", @setModel
        @_picker.on "open", => @closeOtherHelpers(@_picker)

    if _ed.getOption('asset_styles')
      if styler_view_class_name = @getOption('stylerView')
        if styler_view_class = Ed.Views[styler_view_class_name]
          @_styler = new styler_view_class
            model: @model
          @_styler.$el.appendTo @ui.buttons
          @_styler.render()
          @_styler.on "styled", @setStyle
          @_styler.on "open", => @closeOtherHelpers(@_styler)


  ## Selection controls
  #
  setModel: (model) =>
    @log "🤡 setModel", model
    @model = model
    @_styler?.setModel(model)
    if @model
      @trigger "select", @model
      @stickit()

  update: =>
    @trigger 'update'

  ## Styling controls
  #
  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()


  ## Dropped-file handlers
  # Live here so as to be applied to the whole asset element.
  # Dropped file is passed to our uploader for processing.
  #
  dragOver: (e) =>
    e?.preventDefault()
    if e.originalEvent.dataTransfer
      e.originalEvent.dataTransfer.dropEffect = 'copy'

  catchFiles: (e) =>
    @lookNormal()
    if e?.originalEvent.dataTransfer?.files.length
      @containEvent(e)
      @readFile e.originalEvent.dataTransfer.files
    else
      console.log "unreadable drop", e

  readFile: (files) =>
    @_uploader.readLocalFile(files[0]) if @_uploader and files.length

  lookAvailable: (e) =>
    e?.stopPropagation()
    @$el.addClass('droppable')

  lookNormal: (e) =>
    e?.stopPropagation()
    @$el.removeClass('droppable')

  ## Click handler
  # allows click anywhere to upload. Event is relayed to uploader.
  #
  pickFile: (e) =>
    e?.preventDefault()
    @_uploader?.pickFile(e)

  ## Menu display

  closeHelpers: =>
    # event allowed through
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close()

  closeOtherHelpers: (helper) =>
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close() unless h is helper


class Ed.Views.ImageEditor extends Ed.Views.AssetEditor
  template: "image_editor"
  pickerView: "ImagePicker"
  importerView: "ImageImporter"

  initialize: (data, options={}) ->
    @collection ?= new Ed.Collections.Images
    super


class Ed.Views.MainImageEditor extends Ed.Views.ImageEditor
  template: "main_image_editor"


class Ed.Views.VideoEditor extends Ed.Views.AssetEditor
  template: "video_editor"
  pickerView: "VideoPicker"
  importerView: "VideoImporter"

  initialize: ->
    @collection ?= new Ed.Collections.Videos
    super


class Ed.Views.QuoteEditor extends Ed.Views.AssetEditor
  template: "quote_editor"
  importerView: false
  uploaderView: false


class Ed.Views.ButtonEditor extends Ed.Views.AssetEditor
  template: "button_editor"
  importerView: false
  uploaderView: false


## Asset pickers
#
# Display a list of assets, receive a selection click and call setModel on the Asset container.
#
class Ed.Views.AssetPicker extends Ed.Views.MenuView
  tagName: "div"
  className: "picker"
  listView: "AssetList"

  ui:
    head: ".menu-head"
    body: ".menu-body"
    list: ".pick"
    closer: "a.close"

  initialize: ->
    super
    @collection.on 'add remove reset', @setVisibility

  onRender: =>
    super
    @setVisibility()

  onOpen: =>
    unless @_list_view
      list_view_class = @getOption('listView')
      @_list_view = new Ed.Views[list_view_class]
        collection: @collection
      @ui.list.append @_list_view.el
      @log "🤡 onOpen appending list view to", @ui.list
      @_list_view.on "select", @selectModel
    @collection.reload()
    @_list_view.render()

  # passed back to the Asset view.
  selectModel: (model) =>
    @close()
    @trigger "select", model

  setVisibility: =>
    if @collection.length
      @$el.show()
    else
      @$el.hide()
    

class Ed.Views.ImagePicker extends Ed.Views.AssetPicker
  template: "image_picker"
  listView: "ImageList"


class Ed.Views.VideoPicker extends Ed.Views.AssetPicker
  template: "video_picker"
  listView: "VideoList"


## Asset uploaders
#
# Take a file, turn it into an Asset and call setModel on the Asset container.
#
class Ed.Views.AssetUploader extends Ed.View
  template: "asset_uploader"
  tagName: "div"
  className: "uploader"

  ui:
    label: "label"
    filefield: 'input[type="file"]'
    prompt: ".prompt"

  events:
    "click @ui.filefield": "containEvent"
    "change @ui.filefield": "getPickedFile"
    "click @ui.label": "triggerPick"

  ## Picked-file handlers
  #
  # `pickFile` can be called from outside the uploader.
  pickFile: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @trigger 'pick'
    @ui.filefield.click()

  triggerPick: =>
    # event is allowed to continue.
    @trigger 'pick'

  # then `getPickedFile` is called on filefield change.
  getPickedFile: (e) =>
    if files = @ui.filefield[0].files
      @readLocalFile files[0]

  # `readLocalFile` is called either from here or from the outer Editor on file drop.
  readLocalFile: (file) =>
    if file?
      reader = new FileReader()
      reader.onloadend = =>
        @createModel reader.result, file
      reader.readAsDataURL(file)

  createModel: (data, file) =>
    model = @collection.add
      file_data: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    @trigger "select", model
    model.save().done =>
      @trigger "create", model

  containEvent: (e) =>
    e?.stopPropagation()


  ## Asset importers
  #
  # Take a URL, turn it into an Asset and call setModel on the Asset container.
  #
  class Ed.Views.AssetImporter extends Ed.Views.MenuView
    tagName: "div"
    className: "importer"

    ui:
      head: ".menu-head"
      body: ".menu-body"
      url: "input.remote_url"
      button: "a.submit"
      closer: "a.close"
      waiter: "p.waiter"

    events:
      "click @ui.head": "toggleMenu"
      "click @ui.closer": "close"
      "click @ui.button": "createModel"

    createModel: =>
      if remote_url = @ui.url.val()
        model = @collection.add
          remote_url: remote_url
        @trigger 'select', model
        @disableForm()
        model.save().done =>
          @trigger 'create', model
          @resetForm()
          @close()

    disableForm: =>
      @ui.url.attr('disabled', true)
      @ui.button.addClass('waiting')
      @ui.waiter.show()

    resetForm: =>
      @ui.button.removeClass('waiting')
      @ui.url.removeAttr('disabled')
      @ui.waiter.hide()
      @ui.url.val("")


  class Ed.Views.ImageImporter extends Ed.Views.AssetImporter
    template: "image_importer"


  class Ed.Views.VideoImporter extends Ed.Views.AssetImporter
    template: "video_importer"













## Asset-choosers
#
# The submenu for each asset picker is a chooser-list.
# These are small thumbnail galleries with add and import controls alongside.
#
class Ed.Views.ListedAsset extends Ed.View
  template: "listed"
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


class Ed.Views.NoListedAsset extends Ed.View
  template: "none"
  tagName: "li"
  className: "empty"



class Ed.Views.AssetList extends Ed.CollectionView
  childView: Ed.Views.ListedAsset
  emptyView: Ed.Views.NoListedAsset
  tagName: "ul"
  className: "ed-assets"

  childViewTriggers:
    'select': 'select'


class Ed.Views.ImageList extends Ed.Views.AssetList


class Ed.Views.VideoList extends Ed.Views.AssetList



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
        allowMultiParagraphSelection: true
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
          name: 'orderedlist'
          contentDefault: '<svg><use xlink:href="#ol_button"></use></svg>'
        ,
          name: 'unorderedlist'
          contentDefault: '<svg><use xlink:href="#ul_button"></use></svg>'
        ,
          name: 'h2'
          contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
        ,
          name: 'h3'
          contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
        ,
          name: 'removeFormat'
          contentDefault: '<svg><use xlink:href="#clear_button"></use></svg>'
        ]





## Asset styles
#
# All the assets get the same layout options, selected by buttons in this view.

class Ed.Views.AssetStyler extends Ed.View
  tagName: "div"
  className: "styler"
  template: "styler"
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
  template: "weighter"

  ui:
    head: ".menu-head"
    body: ".menu-body"

  events:
    "click @ui.head": "toggleMenu"

  bindings: 
    "input.weight": "main_image_weighting"










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


class Ed.Views.Helper extends Ed.View
  template: false

  ui:
    shower: "a.show"
    help: ".help"

  events:
    "click a.show": "toggle"

  onRender: =>
    @stickit()

  toggle: (e) =>
    if @$el.hasClass('showing')
      @$el.removeClass 'showing'
    else
      @$el.addClass 'showing'






