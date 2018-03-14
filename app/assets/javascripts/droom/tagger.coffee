$.fn.tagger = ->
  @each ->
    new TagChooser(@)

$.fn.faceter = ->
  @each ->
    new TagFaceter(@)


class Tagger
  constructor: (el) ->
    @_el = $(el)
    @_tags = @_el.find("#tags")
    @_field = @_el.find('input.tagger')
    @_form = @_field.parents('form')
    @_adder = @_el.find('a.add_tag')
    if value = @_field.val()
      existing_terms = _.map _.uniq(value.split(',')), (term) -> name: term
    else
      existing_terms = []
    @_field.tokenInput "/droom/api/tags",
      minChars: 2
      tokenValue: "name"
      prePopulate: existing_terms
      onResult: (data) ->
        seen = {}
        terms = []
        _.map data, (suggestion) ->
          unless seen[suggestion.term]
            terms.push(name: suggestion.term)
            seen[suggestion.term] = true
        terms
    @_search_field = @_tags.find('input#token-input-item_terms')
    @_search_field.after @_adder
    @_adder.on "click", @accept
    @_field.on "change", @changed
    @_search_field.on "input change", @observeSearch
    @observeSearch()
    if @_el.hasClass('active')
      @focus()  #todo only if terms just applied

  focus: =>
    @_search_field.focus()

  observeSearch: =>
    @_current_tag = @_search_field.val()
    if @_current_tag?.length > 3
      @_adder.show()
    else
      @_adder.hide()

  accept: =>
    #noop: editor will add new term

  changed: =>
    #noop: faceting form will submit automatically


class TagChooser extends Tagger
  accept: =>
    @_field.tokenInput "add", name: @_current_tag
    @_search_field.val("")
    @observeSearch()


class TagFaceter extends Tagger
  changed: =>
    @_el.addClass('waiting')
    @_form.submit()

  close: =>
    @_field.tokenInput('clear')
    @_el.removeClass('active')
    @changed()

