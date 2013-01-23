jQuery ($) ->
  class Search
    constructor: (element) ->
      @form = $(element)
      @search_box = @form.find(".search_box")
      @container = $(".search_results")
      @search_box.on "keyup", @submit

    submit: =>
      $.ajax
        url: "#{@form.attr('action')}?term=#{@search_box.val()}"
        type: "GET"
        dataType: "script"
        complete: (data) =>
          @container.replaceWith data.responseText
          @container = $(".search_results")

  $.fn.search = ->
    @each ->
      new Search @
      
  $.namespace "Droom", (target, top) ->
    target.Search = Search
