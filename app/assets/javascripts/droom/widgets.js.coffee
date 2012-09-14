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
      
$ ->
  $('.twister').twister()