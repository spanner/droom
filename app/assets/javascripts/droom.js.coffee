#= require droom/lib/modernizr
#= require jquery
#= require jquery_ujs
#= require droom/lib/ZeroClipboard
#= require droom/lib/jquery.animate-colors
#= require droom/lib/jquery.sortable
#= require droom/lib/jquery.cookie
#= require droom/lib/kalendae
#= require droom/lib/wysihtml5
#= require droom/lib/parser_rules/advanced
#= require droom/extensions
#= require droom/utilities
#= require droom/ajax
#= require droom/popups
#= require droom/actions
#= require droom/widgets
#= require droom/map
#= require_self

jQuery ($) ->
  $.activate_with () ->
    @find_including_self('input:radio').trigger_change_on_deselect()
    @find_including_self('#flashes p:parent').flash()
    @find_including_self('[data-refreshable]').refresher()
    @find_including_self('.hidden').find('input, select, textarea').attr('disabled', true)
    
    # link actions
    
    @find_including_self('[data-action="remove"]').removes()
    @find_including_self('[data-action="copy"]').copier()
    @find_including_self('[data-action="popup"]').popup()
    @find_including_self('[data-action="column_toggle"]').column_expander()
    @find_including_self('[data-action="fetch"]').replace_with_remote_content()
    @find_including_self('[data-action="twister"]').twister()
    @find_including_self('[data-action="filter"]').search_filter()
    @find_including_self('[data-action="toggle"]').toggle()
    @find_including_self('[data-action="alternate"]').alternator()
    
    # and some shortcuts for compatibility
    
    @find_including_self('a.inline, a.fetch').replace_with_remote_content()
    
    # form widgets and input modification. These might move to [data-widget] markup.
    
    @find_including_self('.wysihtml').html_editable()
    @find_including_self('.venuepicker').venue_picker()
    @find_including_self('.datepicker').date_picker()
    @find_including_self('.timepicker').time_picker()
    @find_including_self('.filepicker').file_picker()
    @find_including_self('.person_picker').person_picker()
    @find_including_self('.group_picker').group_picker()
    @find_including_self('.drag_sort').drag_sort()
    @find_including_self('input.password').password_field()
    @find_including_self('input[type="submit"]').submitter()
    @find_including_self('span.preference').preference_block()
    
    # page widgets
    
    @find_including_self('table.sortable').table_sort()
    @find_including_self('#map').init_map()
    @find_including_self('#minicalendar').calendar()
    @find_including_self('form.search_form').search()
    @find_including_self('form.fancy').captive
    @find_including_self('div.folder').folder()
    @find_including_self('form#searchform').suggestion_form
      replacing: '.search_results'
      fast: true
    @
