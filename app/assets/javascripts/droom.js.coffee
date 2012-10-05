#= require droom/lib/modernizr
#= require droom/lib/extensions
#= require jquery
#= require jquery_ujs
#= require droom/lib/jquery.animate-colors
#= require droom/lib/kalendae
#= require droom/lib/wysihtml5
#= require droom/lib/parser_rules/advanced
#= require droom/forms
#= require droom/suggester
#= require droom/calendar
#= require droom/sort
#= require droom/map
#= require_self

jQuery ($) ->
  $.fn.flash = ->
    @each ->
      container = $(this)
      container.fadeIn "fast"
      $("<a href=\"#\" class=\"closer\">close</a>").prependTo(container)
      container.bind "click", (e) ->
        e.preventDefault()
        container.fadeOut "fast"

  $.fn.signal = (color, duration) ->
    color ?= "#f7f283"
    duration ?= 1000
    @each ->
      $(@).css('backgroundColor', color).animate({'backgroundColor': '#ffffff'}, duration)
      
  $.fn.signal_confirmation = ->
    @notify('#8dd169')

  $.fn.signal_error = ->
    @notify('#e55a51')

  $.fn.signal_cancellation = ->
    @notify('#a2a3a3')

  $.fn.activate = () ->
    @find('#flashes p:parent').flash()
    @find('.twister').twister()
    @find('.wysihtml').html_editable()
    @find('.venuepicker').venue_picker()
    @find('.datepicker').date_picker()
    @find('.timepicker').time_picker()
    @find('.filepicker').file_picker()
    
    @find('[data-action="popup"]').popup_remote_content()
    @find('[data-action="toggle"]').toggle()
    @find('[data-action="append_form"]').append_remote_form()
    @find('[data-action="overlay_form"]').overlay_remote_form()
    @find('[data-action="replace_with_form"]').replace_with_remote_form()
    
    @find('table.sortable').table_sort
      sort: "created"
      order: "DESC"
    @find('#map').init_map()
    
    @find('[data-refreshable]').refresher()
      
$ ->
  $('body').activate()
  $('#minicalendar').calendar()
  $('form#searchform').captive
    replacing: '.search_results'
    fast: true
