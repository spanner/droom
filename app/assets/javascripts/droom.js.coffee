#= require droom/lib/modernizr
#= require droom/lib/extensions
#= require jquery
#= require jquery_ujs
#= require droom/lib/ZeroClipboard
#= require droom/lib/jquery.animate-colors
#= require droom/lib/jquery.sortable
#= require droom/lib/jquery.cookie
#= require droom/lib/kalendae
#= require droom/lib/wysihtml5
#= require droom/lib/parser_rules/advanced
#= require droom/utilities
#= require droom/forms
#= require droom/suggester
#= require droom/calendar
#= require droom/sort
#= require droom/map
#= require droom/drag_sort
#= require_self

jQuery ($) ->
  $.activate_with () ->
    @find_including_self('#flashes p:parent').flash()
    @find_including_self('.wysihtml').html_editable()
    @find_including_self('.venuepicker').venue_picker()
    @find_including_self('.datepicker').date_picker()
    @find_including_self('.timepicker').time_picker()
    @find_including_self('.filepicker').file_picker()
    @find_including_self('a.delete').removes('.holder')
    @find_including_self('[data-action="copy"]').copier()
    @find_including_self('[data-action="popup"]').popup_remote_content()
    @find_including_self('[data-action="toggle"]').toggle()
    @find_including_self('[data-action="reveal"]').replace_with_remote_content()
    @find_including_self('[data-action="twister"]').twister()
    @find_including_self('[data-refreshable]').refresher()
    @find_including_self('table.sortable').table_sort()
    @find_including_self('#map').init_map()
    @find_including_self('input.password').password_field()
    @find_including_self('input[type="submit"]').submitter()
    @find_including_self('input.person_picker').person_picker()
    @find_including_self('input.group_picker').group_picker()
    @find_including_self('.drag_sort').drag_sort()
    @find_including_self('.back').back_button()
    @find_including_self('#minicalendar').calendar()
    @find_including_self('a.toggle_active').replace_with_remote_content('.holder')
    @find_including_self('form#searchform').captive
      replacing: '.search_results'
      fast: true
    @find_including_self('[data-focus]').focus()
    @
