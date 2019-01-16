#= require hamlcoffee
#= require 'honeybadger/lib/honeybadger'
#= require 'underscore/underscore'
#= require 'backbone/backbone'
#= require 'backbone.marionette/lib/backbone.marionette'
#= require 'backbone.stickit/backbone.stickit'
#= require 'moment/moment'
#= require 'smartquotes/dist/smartquotes'
#= require 'medium-editor/dist/js/medium-editor'
#= require 'jquery-circle-progress/dist/circle-progress'

#= require_tree ./templates
#= require './ed/application'
#= require './ed/config'
#= require './ed/models'
#= require_tree './ed/views'
#= require_self

jQuery ($) ->
  document.execCommand('defaultParagraphSeparator', false, 'p')

  $.fn.edify = (options={}) ->
    console.log "edify", @, options
    @each ->
      args = _.extend options,
        el: @
      new Ed.Application(args).start()

  $('[data-editor="ed"]').edify()
