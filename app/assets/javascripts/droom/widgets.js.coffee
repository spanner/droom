jQuery ($) ->
  
  class Twister
    constructor: (element) ->
      console.log "twister!", @
      @_twister = $(element)
      @_twisted = @_twister.siblings('.twisted')
      @_toggle = @_twister.find('a')
      @_toggle.click @toggle
      @close() if @_twister.hasClass('closed')

    toggle: (e) =>
      console.log "toggle", @_twisted
      e.preventDefault() if e
      if @_twisted.is(':visible') then @close() else @open()
      
    open: () =>
      console.log "open"
      @_twister.removeClass("closed")
      @_twisted.slideDown "slow"

    close: () =>
      console.log "close"
      @_twisted.slideUp "slow", () =>
        @_twister.addClass("closed")
  
  $.fn.twister = ->
    @each ->
      new Twister(@)



  # A captive form submits via an ajax request and pushes its results into the present page.

  class CaptiveForm
    constructor: (element, @_options) ->
      console.log "captive!", @, @_options.replacing
      @_form = $(element)
      @_prompt = @_form.find("input[type=\"text\"]")
      @_request = null
      @_original_content = $(@_options.replacing).clone()
      @_form.submit @submit

    submit: (e) =>
      e.preventDefault()  if e
      $(@_options.replacing).fadeTo "fast", 0.2
      @_request.abort() if @_request
      @_form.find("input[type='submit']").addClass "waiting"
      @_request = $.ajax
        type: "GET"
        dataType: "html"
        url: @_form.attr("action") + ".js"
        data: @_form.serialize()
        success: @update

    update: (results) =>
      @_form.find("input[type='submit']").removeClass "waiting"
      @display results

    display: (results) =>
      $(@_options.replacing).replaceWith results
      $(@_options.clearing).val "" if @_options.clearing?


  $.fn.captive = (options) ->
    options = $.extend(
      replacing: "#results"
      clearing: null
    , options)
    @each ->
      new CaptiveForm @, options
    @


  $.fn.fast = ->
    @each ->
      form = $(this)
      form.find("input[type=\"text\"]").not(".suggestible").addClass("significant").keyup (e) ->
        k = e.which
        form.submit() if (k >= 49 and k <= 122) or k

      form.find("input[type=\"radio\"]").addClass("significant").click (e) ->
        form.submit()

      form.find("input[type=\"checkbox\"]").addClass("significant").click (e) ->
        form.submit()

      form.find("input[type=\"submit\"]").hide()
    @

$ ->
  $('.twister').twister()
  $('form#search').captive({replacing: '#search_results'}).fast()
  