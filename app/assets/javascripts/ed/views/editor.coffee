# This is an html-composition helper. It binds to a contenteditable div and adds tools
# for the formatting of text and the insertion and management of non-text elements.
#
# The only thing we bring to here and take away is the composed html. The body editor
# can read its output well enough to reconstitute editing state.

class Ed.Views.Editor extends Ed.View
  ui:
    title: ".ed-title"
    slug: ".ed-slug"
    content: ".ed-content"
    image: ".ed-image"
    titlefield: '[data-ed="title"]'
    slugfield: '[data-ed="slug"]'
    contentfield: '[data-ed="content"]'
    imagefield: '[data-ed="image"]'

  bindings:
    '[data-ed="title"]':
      observe: "title"
      updateModel: false
    '[data-ed="slug"]':
      observe: "slug"
      updateModel: false
    '[data-ed="image"]':
      observe: "image_id"
      updateModel: false
    '[data-ed="content"]':
      observe: "content"
      onGet: "cleanContent"
      updateModel: false

  wrap: =>
    window.model = @model = new Ed.Models.Editable
    @ui.title.each (i, el) =>
      @subviews.push new Ed.Views.Title
        el: el
        model: @model
    @ui.slug.each (i, el) =>
      @subviews.push new Ed.Views.Slug
        el: el
        model: @model
    @ui.content.each (i, el) =>
      @subviews.push new Ed.Views.Content
        el: el
        model: @model
    @ui.image.each (i, el) =>
      @subviews.push new Ed.Views.MainImage
        el: el
        model: @model

  cleanContent: (content, model) =>
    wrapper = $('<div />').html(content)
    wrapper.find('[contenteditable], [contenteditable="false"]').removeAttr('contenteditable')
    wrapper.find('[data-placeholder]').removeAttr('data-placeholder')
    wrapper.find('.ed-buttons').remove()
    wrapper.find('.ed-progress').remove()
    wrapper.find('.ed-action').remove()
    wrapper.html()


class Ed.Views.Title extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'title'

  wrap: =>
    @model.set 'title', @$el.text().trim()


class Ed.Views.Slug extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'slug'

  wrap: =>
    @model.set 'slug', @$el.text().trim()


class Ed.Views.Content extends Ed.View
  template: false
  ui:
    content: ".content"
    placeholder: ".placeholder"

  bindings: 
    '.content':
      observe: 'content'
      updateView: false

  wrap: =>
    content = @ui.content.html().trim()
    @model.set 'content', content, silent: true
    @showPlaceholderIfEmpty()
    @ui.content.on 'blur', @showPlaceholderIfEmpty
    @ui.content.addClass 'editing'
    window.cont = @

    @ui.content.find('figure.image').each (i, el) =>
      @subviews.push new Ed.Views.Image
        el: el
    @ui.content.find('figure.video').each (i, el) =>
      @subviews.push new Ed.Views.Video
        el: el
    @ui.content.find('figure.quote').each (i, el) =>
      @subviews.push new Ed.Views.Quote
        el: el
    @ui.content.find('a.button').each (i, el) =>
      @subviews.push new Ed.Views.Button
        el: el

  showPlaceholderIfEmpty: =>
    if @ui.content.text().trim()
      @ui.placeholder.hide()
      @ui.content.show()
    else
      @ui.content.hide()
      @_inserter?.hide()
      @ui.placeholder.show()
      @ui.placeholder.click =>
        @ui.placeholder.hide()
        @ui.content.show().focus()

  onRender: =>
    @stickit()

    @_inserter = new Ed.Views.AssetInserter
    @_inserter.render()
    @_inserter.attendTo(@ui.content)

    @_toolbar = new MediumEditor @ui.content,
      placeholder: false
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: false
        imageDragging: false
        commands: [
          {
            command: 'link',
            key: 'K',
            meta: true,
            shift: false,
            alt: false
          }
        ]
        buttons: [
          {
            name: 'bold'
            contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
          },
          {
            name: 'italic'
            contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
          },
          {
            name: 'anchor'
            contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
          },
          {
            name: 'h2'
            contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
            aria: "Major heading"
          },
          {
            name: 'h3'
            contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
            aria: "Minor heading"
          }
        ]



## Individual Asset Managers
#
# The html we get and set can include a number of embedded assets...
#
class Ed.Views.Asset extends Ed.View
  defaultSize: "full"

  ui:
    buttons: ".ed-buttons"

  initialize: =>
    @_size ?= _.result @, 'defaultSize'
    super

  wrap: =>
    #required in subclass to extract model properties from html.

  onRender: () =>
    @log "render"
    @$el.attr "contenteditable", false
    @stickit() if @model
    if picker_view_class = @getOption('pickerView')
      @_picker = new picker_view_class
      @_picker.$el.appendTo @ui.buttons
      @_picker.render()
      @_picker.on "select", @setModel
      @_picker.on "create", @savedModel
      @_picker.on "remove", @remove
    if styler_view_class = @getOption('stylerView')
      @_styler = new styler_view_class
        model: @model
      @_styler.$el.appendTo @ui.buttons
      @_styler.render()
      @_styler.on "styled", @setStyle
    @_progress = new Ed.Views.ProgressBar
      model: @model
      size: 100
      thickness: 10
    @_progress.$el.appendTo @$el
    @_progress.render()

  setModel: (model) =>
    @log "setModel", model
    @model = model
    @stickit() if @model
    @_styler?.setModel(model)
    @_progress?.setModel(model)
    @trigger "select"
    @update()

  update: =>
    @$el.parent().trigger 'input'

  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()

  remove: () =>
    @$el.slideUp 'fast', =>
      @$el.remove()
      @update()

  # bindings for use within an asset model.
  #
  urlAtSize: (url) =>
    @model.get("#{@_size}_url") ? url

  backgroundAtSize: (url) =>
    if url
      "background-image: url('#{@urlAtSize(url)}')"

  weightedBackground: ([url, weighting]=[]) =>
    style = ""
    if url
      style += "background-image: url('#{@urlAtSize(url)}')"
      if weighting
        style += "; background-position: #{weighting}')"
    style


class Ed.Views.MainImage extends Ed.Views.Asset
  pickerView: Ed.Views.MainImagePicker
  template: false
  defaultSize: "hero"

  ui:
    buttons: ".ed-buttons"

  wrap: =>
    @$el.addClass 'editing'
    if image_id = @$el.data('image')
      _ed.withAssets =>
        @setModel _ed.images.get(image_id)

  setModel: (image) =>
    @log "setModel", image
    @bindImage(image)
    @model.set "image", image, stickitChange: true
    @_progress?.setModel(image)
    @stickit()

  bindImage: (image) =>
    if @image
      @unstickit @image
    if image
      @log "BINDING", image
      @image = image
      @addBinding @image, ":el",
        attributes: [
          name: "style"
          observe: "url"
          onGet: "backgroundAtSize"
        ]


class Ed.Views.Image extends Ed.Views.Asset
  pickerView: Ed.Views.ImagePicker
  stylerView: Ed.Views.AssetStyler
  template: "assets/image"
  tagName: "figure"
  className: "image full"
  defaultSize: "full"

  events:
    "click a.save": "saveImage"

  bindings:
    ":el":
      attributes: [
        name: "data-image",
        observe: "id"
      ]
    "img":
      attributes: [
        name: "src"
        observe: "url"
        onGet: "urlAtSize"
      ]
    "figcaption":
      observe: "caption"
    "a.save":
      observe: "changed"
      visible: true

  wrap: =>
    if image_id = @$el.data('image')
      _ed.withAssets =>
        @setModel _ed.images.get(image_id) ? new Ed.Models.Image
    else 
      @model = new Ed.Models.Image

  saveImage: (e) =>
    e?.preventDefault()
    @model.save()


class Ed.Views.Video extends Ed.Views.Asset
  pickerView: Ed.Views.VideoPicker
  stylerView: Ed.Views.AssetStyler
  template: "assets/video"
  tagName: "figure"
  className: "video full"
  defaultSize: "full"

  events:
    "click a.save": "saveVideo"

  bindings:
    ":el":
      attributes: [
        name: "data-video",
        observe: "id"
      ]
    ".embed":
      observe: "embed_code"
      visible: true
      updateView: true
      updateMethod: "html"
    "video":
      observe: "embed_code"
      visible: "unlessEmbedded"
      visibleFn: "hideVideo"
    "figcaption":
      observe: "caption"

  wrap: =>
    @$el.addClass 'editing'
    if video_id = @$el.data('video')
      _ed.withAssets =>
        @setModel _ed.videos.get(video_id ) ? new Ed.Models.Video

  unlessEmbedded: (embed_code) =>
    console.log "unlessEmbedded", !embed_code
    !embed_code

  hideVideo: (el, visible, model) =>
    el.hide() unless visible


class Ed.Views.Quote extends Ed.Views.Asset
  pickerView: Ed.Views.QuotePicker
  stylerView: Ed.Views.AssetStyler
  template: "assets/quote"
  tagName: "figure"
  className: "quote full"
  defaultSize: "full"

  ui:
    buttons: ".ed-buttons"
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
    @render()

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
  stylerView: Ed.Views.AssetStyler
  template: "assets/button"
  tagName: "a"
  className: "button full"
  defaultSize: "full"

  ui:
    buttons: ".ed-buttons"
    label: "span.label"

  bindings:
    ":el":
      attributes: [
        name: "class"
        observe: "label"
        onGet: "classFromLength"
      ]
    "span.label":
      observe: "label"

  wrap: =>
    @model = new Ed.Models.Button
      label: @ui.label.text()
    @render()

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

