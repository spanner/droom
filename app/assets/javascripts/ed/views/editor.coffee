# This is an html-composition helper. It binds to a contenteditable div and adds tools
# for the formatting of text and the insertion and management of non-text elements.
#
# The only thing we bring to here and take away is the composed html. The body editor
# can read its output well enough to reconstitute editing state.

class Ed.Views.Editor extends Ed.View
  ui:
    title: ".ed-title"
    subtitle: ".ed-subtitle"
    intro: ".ed-intro"
    slug: ".ed-slug"
    content: ".ed-content"
    image: ".ed-image"
    image_caption: ".ed-imagecaption"
    checkers: '[data-ed-check]'
    helpers: '.ed-help'

  bindings:
    '[data-ed="title"]':
      observe: "title"
      updateModel: false
    '[data-ed="subtitle"]':
      observe: "subtitle"
      updateModel: false
    '[data-ed="intro"]':
      observe: "intro"
      updateModel: false
    '[data-ed="slug"]':
      observe: "slug"
      updateModel: false
    '[data-ed="main_image_id"]':
      observe: "main_image_id"
      updateModel: false
    '[data-ed="main_image_weighting"]':
      observe: "main_image_weighting"
      updateModel: false
    '[data-ed="main_image_caption"]':
      observe: "main_image_caption"
      updateModel: false
    '[data-ed="content"]':
      observe: "content"
      onGet: "cleanContent"
      updateModel: false
    '[data-ed="submit"]':
      observe: "busy"
      update: "disableWhenBusy"

  wrap: =>
    @ui.title.each (i, el) =>
      @subviews.push new Ed.Views.Title
        el: el
        model: @model
    @ui.subtitle.each (i, el) =>
      @subviews.push new Ed.Views.Subtitle
        el: el
        model: @model
    @ui.intro.each (i, el) =>
      @subviews.push new Ed.Views.Intro
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
    @ui.image_caption.each (i, el) =>
      @subviews.push new Ed.Views.ImageCaption
        el: el
        model: @model
    @ui.checkers.each (i, el) =>
      @subviews.push new Ed.Views.Checker
        el: el
        model: @model
    @ui.helpers.each (i, el) =>
      @subviews.push new Ed.Views.Helper
        el: el
        model: @model

  onRender: =>
    @log "🦋 editor", @el
    @stickit()
    @placeCaret()
    window.m = @model
    # _.defer -> balanceText('.balanced')

  placeCaret: =>
    if title_el = @ui.title.get(0)
      range = document.createRange()
      range.setStart title_el, 0
      range.collapse true
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range

  cleanContent: (content, model) =>
    @model.cleanContent()

  disableWhenBusy: ($el, busy, model, options) =>
    if busy
      $el.disable()
    else
      $el.enable()


class Ed.Views.Title extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'title'

  wrap: =>
    @model.set 'title', @$el.text().trim()


class Ed.Views.Subtitle extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'subtitle'

  wrap: =>
    @model.set 'subtitle', @$el.text().trim()


class Ed.Views.Slug extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'slug'

  wrap: =>
    @model.set 'slug', @$el.text().trim()


class Ed.Views.Intro extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'intro'

  wrap: =>
    @model.set 'intro', @$el.text().trim()


class Ed.Views.ImageCaption extends Ed.View
  template: false
  bindings: 
    ':el':
      observe: 'main_image_caption'

  wrap: =>
    @model.set 'main_image_caption', @$el.text().trim()


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

    @ui.content.find('section.blockset').each (i, el) =>
      @subviews.push new Ed.Views.Blocks
        el: el
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

    @ui.content.on('focus', @ensureP).on('blur', @clearP)

    @ui.placeholder.click =>
      @ui.placeholder.hide()
      @ui.content.show().focus()

  showPlaceholderIfEmpty: =>
    if @ui.content.text().trim()
      @hidePlaceholder()
    else
      @showPlaceholderSoon()

  hidePlaceholder: =>
    @ui.placeholder.hide()
    @ui.content.show()

  showPlaceholder: =>
    @ui.content.hide()
    @_inserter?.hide()
    @ui.placeholder.show()

  showPlaceholderSoon: =>
    @dontShowPlaceholder()
    @_placeholdershower = window.setTimeout @showPlaceholder, 500

  dontShowPlaceholder: =>
    if @_placeholdershower
      window.clearTimeout @_placeholdershower 

  onRender: =>
    @stickit()

    @_inserter = new Ed.Views.AssetInserter
    @_inserter.render()
    @_inserter.attendTo @ui.content
    @_inserter.on 'expand', @dontShowPlaceholder

    @_toolbar = new Ed.Views.Toolbar
      target: @ui.content
    @_toolbar.render()

    @ui.content.on "focus", @ensureP
    @ui.content.on "blur", @removeEmptyP

  ## Contenteditable helpers from chemistry
  # Small intervention to make contenteditable behave in a slightly saner way,
  # eg. by definitely typing into an (apparently) empty <p> element.
  #
  ensureP: (e) =>
    el = e.target
    if el.innerHTML.trim() is ""
      el.style.minHeight = el.offsetHeight + 'px'
      p = document.createElement('p')
      p.innerHTML = "&#8203;"
      el.appendChild p

  clearP: (e) =>
    el = e.target
    content = el.innerHTML
    el.innerHTML = "" if content is "<p>&#8203;</p>" or content is "<p><br></p>" or content is "<p>​</p>"  # there's a zwsp in that last string


class Ed.Views.Checker extends Ed.View
  template: false

  ui:
    counter: 'span.count'

  wrap: =>
    @attribute = @$el.data('ed-check')
    @addBinding null, ':el',
      observe: @attribute
      update: "attributePresent"
    @addBinding null, 'use.check',
      attributes: [
        name: "xlink:href"
        observe: @attribute
        onGet: "checkSymbol"
      ]

  attributePresent: ($el, value, model, options) =>
    present = false
    if @attribute is 'content'
      value = @model.textContent()
      if value.trim() is ""
        word_count = 0
        @ui.counter.text ''
      else
        words = _.filter value.split(/\W+/), (w) -> !!w.trim()
        word_count = words.length
        word_word = if word_count is 1 then " word" else " words"
        @ui.counter.text "(You have #{word_count} #{word_word})"

      present = word_count > 20
    else
      present = value
    if present
      $el.removeClass('missing').addClass('present')
    else
      $el.removeClass('present').addClass('missing')

  checkSymbol: (value) =>
    if value then "#tick_symbol" else "#cross_symbol"



