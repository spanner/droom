#= require lib/modernizr
#= require lib/extensions
#= require jquery
#= require jquery_ujs
#= require lib/kalendae
#= require lib/wysihtml5
#= require lib/parser_rules/advanced
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

  $.fn.activate = () ->
    @find('#flashes p:parent').flash()
    @find('.twister').twister()
    @find('.wysihtml').html_editable()
    @find('.venuepicker').venue_picker()
    @find('.datepicker').date_picker()
    @find('.timepicker').time_picker()
    @find('a.popup').popup_remote_content()
    @find('a.append').append_remote_content()
    @find('#minicalendar').calendar()
    @find('table.sortable').table_sort
      sort: "name"
      order: "ASC"
    @find('#map').init_map()
      
$ ->
  $('body').activate()
  $('form#searchform').captive
    replacing: '.search_results'
    fast: true
