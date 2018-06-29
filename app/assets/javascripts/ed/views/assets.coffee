# Listed assets
#
# The submenu for each asset picker is a chooser-list derived AssetList.
#
class Ed.Views.ListedAsset extends Ed.View
  template: "ed/listed"
  tagName: "li"
  className: "asset"

  events:
    "click a.delete": "deleteMe"
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

  deleteMe: (e) =>
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


class Ed.Views.AssetList extends Ed.CollectionView
  childView: Ed.Views.ListedAsset
  tagName: "ul"
  className: "ed-assets"

  childViewTriggers:
    'select': 'select'


class Ed.Views.ImageList extends Ed.Views.AssetList


class Ed.Views.VideoList extends Ed.Views.AssetList



## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Ed.Views.Asset extends Ed.View
  defaultSize: "full"
  editorView: "AssetEditor"

  ui:
    buttons: ".ed-buttons"
    catcher: ".ed-dropmask"
    prompt: ".prompt"
    overlay: ".darken"

  events:
    "dragenter": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"
    "click @ui.catcher": "pickFile"

  initialize: =>
    super
    @_size ?= _.result @, 'defaultSize'

  onRender: =>
    @log "onRender", @el
    @$el.attr "contenteditable", false
    @stickit() if @model
    @addEditor()

  addEditor: =>
    if editor_view_class = Ed.Views[@getOption('editorView')]
      @_editor = new editor_view_class
        model: @model
      @_editor.$el.appendTo @$el
      @_editor.render()
      @_editor.on 'remove', @remove
      @_editor.on 'update', @update
      @_editor.on 'select', @setModel

  update: =>
    @log "update", @$el.parent()
    @$el.parent().trigger 'input'

  remove: () =>
    @$el.slideUp 'fast', =>
      @update()
      p = $("<p />").insertBefore @$el
      @$el.remove()
      p.focus()

  setModel: (model) =>
    @model = model
    @stickit() if @model
    @update()



## Image assets
#
class Ed.Views.Image extends Ed.Views.Asset
  editorView: "ImageEditor"
  template: "ed/image"
  className: "image full"
  defaultSize: "full"

  bindings:
    ":el":
      attributes: [
        name: "data-image",
        observe: "id"
      ]
    "img":
      attributes: [
        name: "src"
        observe: ["file_url", "file_data"]
        onGet: "thisOrThat"
      ]

  wrap: =>
    @log "🤡 wrap", @$el.data('image')
    if image_id = @$el.data('image')
      @log "🤡 ->", _ed.images.get(image_id)
      @model = _ed.images.get(image_id)
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Ed.Models.Image
    super


class Ed.Views.BackgroundImage extends Ed.Views.Image
  template: false
  className: "bg"

  bindings:
    ":el":
      attributes: [
        name: "data-image",
        observe: "id"
      ,
        name: "style",
        observe: ["file_url", "file_data"]
        onGet: "styleBackgroundImage"
      ]


# Main image is an asset view but it has the main editable as model,
# and on selection we assign the asset to its main_image association
# rather than embedding a view with the asset as model.
#
class Ed.Views.MainImage extends Ed.Views.Asset
  editorView: "MainImageEditor"
  template: false
  defaultSize: "hero"

  wrap: =>
    @$el.addClass 'editing'
    @log "🤡 wrap", @$el.data('image')
    if image_id = @$el.data('image')
      @log "🤡 ->", _ed.images.get(image_id)
      @setModel _ed.images.get(image_id)
    else
      @setModel(null)

    # @model.on "change:main_image_weighting", @setWeighting
    # if weighting = @$el.css('background-position')
    #   named_weighting = weighting.replace(/^100%/g, 'right').replace(/^50%/g, 'center').replace(/^0%*/g, 'left').replace(/100%$/g, 'bottom').replace(/50%$/g, 'center').replace(/0%*$/g, 'top')
    #   @model.set 'main_image_weighting', named_weighting

  # setModel is overridden to assign an the incoming image to our existing model as its `main_image` attribute.
  #
  setModel: (image) =>
    @log "setModel", image
    @bindImage(image)
    @model.setImage(image)
    @_progress?.setModel(image)

  bindImage: (image) =>
    if @image
      @unstickit @image
    if image
      @log "bindImage", image
      @image = image
      @addBinding @image, ":el",
        attributes: [
          name: "style"
          observe: "url"
          onGet: "styleBackgroundAtSize"
        ]
      @ui.overlay.show()
      @ui.prompt.hide()
    else
      @log "unbindImage"
      @$el.css
        'background-image': ''
      @ui.prompt.show()
      @ui.overlay.hide()
    @stickit()

  # not a simple binding because in this context, weighting is a property of the Editable not the image
  # and we can only bind the `style` attribute as a whole.
  # setWeighting: (model, weighting) =>
  #   @log "setWeighting", weighting, @el
  #   if weighting
  #     @$el.css
  #       'background-position': weighting
  #   else
  #     @$el.css('background-position', '')


## Video assets
#
class Ed.Views.Video extends Ed.Views.Asset
  editorView: "VideoEditor"
  template: "ed/video"
  className: "video full"
  defaultSize: "full"

  bindings:
    ":el":
      attributes: [
        name: "data-video",
        observe: "id"
      ]
    ".embed":
      observe: "embed_code"
      updateMethod: "html"
    "video":
      observe: ["file_url", "embed_code"]
      visible: "thisButNotThat"
      attributes: [
        name: "id"
        observe: "id"
        onGet: "videoId"
      ,
        name: "poster"
        observe: "full_url"
      ]
    "img":
      attributes: [
        name: "src"
        observe: "full_url"
      ]
    "source":
      attributes: [
        name: "src"
        observe: "url"
      ]

  wrap: =>
    if video_id = @$el.data('video')
      @model = new Ed.Models.Video(id: video_id)
      @model.load()
      @triggerMethod 'wrap'

  onRender: =>
    @model ?= new Ed.Models.Video
    super

  unlessEmbedded: (embed_code) =>
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible

  videoId: (id) =>
    "video_#{id}"


class Ed.Views.Block extends Ed.View
  template: "ed/block"
  className: "block"

  ui:
    buttons: ".ed-buttons"
    content: ".ed-block"
    remover: "a.remover"

  events:
    "click a.remove": "removeBlock"

  bindings:
    ":el":
      observe: "content"
      updateMethod: "html"
      onGet: "readHtml"

  onRender: =>
    @$el.attr 'contenteditable', true
    @stickit()
    @_toolbar = new Ed.Views.Toolbar
      target: @ui.content
    @_toolbar.render()

  removeBlock: (e) =>
    e?.preventDefault()
    @$el.fadeOut =>
      @model.remove()

  readHtml: (html) =>
    html or "<p></p>"


class Ed.Views.Blocks extends Ed.CompositeView
  template: "ed/blockset"
  tagName: "section"
  className: "blockset"
  childViewContainer: ".blocks"
  childView: Ed.Views.Block

  ui:
    buttons: ".ed-buttons"
    block_holder: ".blocks"
    blocks: ".block"

  events:
    "click a.addblock": "addEmptyBlock"

  wrap: =>
    @collection = new Ed.Collections.Blocks
    if @ui.blocks.length
      @ui.blocks.each (i, block) =>
        $block = $(block)
        @addBlock $block.html()
        $block.remove()
    else
      @addBlock()
      @addBlock()
      @addBlock()

  onRender: =>
    @$el.attr "contenteditable", false
    @setLengthClass()
    @collection.on 'add remove reset', @setLengthClass

  addEmptyBlock: =>
    console.log "addEmptyBlock"
    @collection.add content: ""

  addBlock: (content="") =>
    @collection.add content: content

  setLengthClass: =>
    console.log "setLengthClass", @collection.length
    @ui.block_holder.removeClass('none one two three four').addClass(['none', 'one', 'two', 'three', 'four'][@collection.length])
    if @collection.length >= 4
      @ui.buttons.addClass('inactive')
    else
      @ui.buttons.removeClass('inactive')


## Quote pseudo-assets
#
# Just html, with no reference to an external asset, but editable and stylable like an embedded object.
#
class Ed.Views.Quote extends Ed.Views.Asset
  editorView: "QuoteEditor"
  template: "ed/quote"
  className: "quote full"
  defaultSize: "full"

  ui:
    quote: "blockquote"
    caption: "figcaption"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "utterance"
        onGet: "classFromLength"
      ]
    "blockquote":
      observe: "utterance"
    "figcaption":
      observe: "caption"

  wrap: =>
    @model = new Ed.Models.Quote
      utterance: @$el.find('blockquote').text()
      caption: @$el.find('figcaption').text()
    @log "→ wrapped quote", @el, _.clone(@model.attributes)

  focus: =>
    @ui.quote.focus()

  classFromLength: (text="") =>
    l = text.replace(/&nbsp;/g, ' ').trim().length
    if l < 24
      "veryshort"
    else if l < 48
      "short"
    else if l < 96
      "shortish"
    else
      ""

class Ed.Views.Button extends Ed.Views.Asset
  editorView: "ButtonEditor"
  template: "ed/button"
  tagName: "a"
  className: "button full"
  defaultSize: "full"

  ui:
    buttons: ".ed-buttons"
    label: "span.label"
    url: "span.url"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "label"
        onGet: "classFromLength"
      ,
        name: "href"
        observe: "url"
      ]
    "span.label":
      observe: "label"

  wrap: =>
    @model = new Ed.Models.Button
      label: @ui.label.text()

  focus: =>
    @ui.label.focus()

  classFromLength: (text="") =>
    l = text.replace(/&nbsp;/g, ' ').trim().length
    if l < 10
      "veryshort"
    else if l < 20
      "short"
    else if l < 40
      "shortish"
    else
      ""
