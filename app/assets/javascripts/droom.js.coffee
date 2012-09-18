#= require lib/modernizr
#= require jquery
#= require jquery_ujs
#= require droom/forms
#= require droom/suggester
#= require droom/wysihtml5
#= require droom/parser_rules/advanced
#= require_self

jQuery ($) ->
  $.fn.activate = () ->
    @find('.twister').twister()
    @find('.wysihtml').html_editable()
    @find('.venuepicker').venue_picker()
      
$ ->
  $('body').activate()
  $('form#searchform').captive
    replacing: '.search_results'
    fast: true
  
