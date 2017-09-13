#= require hamlcoffee
#= require 'honeybadger-js/honeybadger'
#= require 'underscore/underscore'
#= require 'backbone/backbone'
#= require 'backbone.marionette/lib/backbone.marionette'
#= require 'backbone.stickit/backbone.stickit'
#= require 'moment/moment'
#= require 'smartquotes/smartquotes'
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

  $.fn.edify = ->
    console.log "edify", @
    @each ->
      new Ed.Application(el: @).start()
