#= require lib/modernizr
#= require jquery
#= require jquery_ujs
#= require lib/kalendae
#= require lib/wysihtml5
#= require lib/parser_rules/advanced
#= require droom/forms
#= require droom/suggester
#= require_self

jQuery ($) ->
  $.fn.activate = () ->
    @find('.twister').twister()
    @find('.wysihtml').html_editable()
    @find('.venuepicker').venue_picker()
    @find('.datepicker').date_picker()
    @find('.timepicker').time_picker()
    @find('a.popup').popup_remote_content()
    @find('a.append').append_remote_content()
      
$ ->
  $('body').activate()
  $('form#searchform').captive
    replacing: '.search_results'
    fast: true
  
