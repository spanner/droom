Ed = {}
Ed.version = '0.1.0'
Ed.subtitle = "𝞪"
Ed.Models = {}
Ed.Collections = {}
Ed.Views = {}

root = exports ? this
root.Ed = Ed

# Ed is a standalone, unrouted backbone marionette application that you can attach to any dom element to 
# manage its html content.

class Ed.Application extends Backbone.Marionette.Application
  defaults:
    asset_styles: null # ['left', 'full', 'right']

  initialize: (opts={}) ->
    root._ed = @
    root.onerror = @reportError
    @original_backbone_sync = Backbone.sync
    Backbone.sync = @sync
    Backbone.Marionette.Renderer.render = @render

    @options = _.extend @defaults, opts
    @el = @options.el
    @_loaded = $.Deferred()
    @_config = new Ed.Config @options.config
    @images = new Ed.Collections.Images
    @videos = new Ed.Collections.Videos
    @notices = new Ed.Collections.Notices
    @initUI()

  region: =>
    @el

  ## Prepare UI
  #
  initUI: (fn) =>
    @model = new Ed.Models.Editable
    @loadAssets()
    @_editor = new Ed.Views.Editor
      model: @model
      el: @el

  reset: =>
    @initUI()

  config: (key) =>
    @_config.get(key)

  loadAssets: () =>
    $.when(@images.fetch(), @videos.fetch()).done =>
      @_loaded.resolve(@images, @videos)
    @_loaded.promise()

  withAssets: (fn) =>
    @_loaded.done fn

  getOption: (key) =>
    @options[key]

  ## Backbone overrides
  # Override sync to add a progress listener to every save
  #
  apiUrl: (path) =>
    base_url = @config('api_url')
    [base_url, path].join('/')

  sync: (method, model, opts) =>
    unless method is "read" or !model.startProgress
      original_success = opts.success
      opts.attrs = model.toJSON()
      model.startProgress("Saving")
      opts.beforeSend = (xhr, settings) ->
        settings.xhr = () ->
          xhr = new window.XMLHttpRequest()
          xhr.upload.addEventListener "progress", (e) ->
            model.setProgress e
          , false
          xhr
      opts.success = (data, status, request) ->
        model.finishProgress(true)
        model.clearTemporaryAttributes()  # eg image file data for upload
        original_success(data, status, request)
    @original_backbone_sync method, model, opts

  # Override render (in marionette) to use our hamlcoffee templates through JST
  #
  render: (template, data) ->
    if template?
      if jst_function = JST["ed/#{template}"]
        jst_function(data)
      else if _.isFunction(template)
        template(data)
      else
        template
    else
      ""


  ## Confirmation and error messages
  #
  # `notify` puts a message on the job queue and returns the relevant announcement,
  # which is a job that can have progress callbacks and other listeners attached to it.
  #
  # In production, all errors are trapped and reported to honeybadger, in the hope that 
  # the ui will remain responsive.
  #
  reportError: (message, source, lineno, colno, error) =>
    complaint = "<strong>#{message}</strong> at #{source} line #{lineno} col #{colno}."
    if @config('display_errors')
      @complain(complaint, 60000)
    if @config('badger_errors')
      Honeybadger.notify error,
        message: complaint
    true if @config('trap_errors')

  confirm: (message, duration=4000) =>
    @notify message, duration, 'confirmation'

  complain: (message, duration=10000) =>
    @notify message, duration, 'error'

  notify: (html_or_text, duration=4000, notice_type='information') =>
    if @_notice_list
      @notices.add
        message: html_or_text
        duration: duration
        notice_type: notice_type
    else
      failure_notice = $('<div class="complete_failure" />').appendTo($("#notices"))
      failure_notice.html("<h2>System failure</h2>" + html_or_text)
      $('.wait').hide()


  ## Logging
  #todo: log level threshold
  #
  log: =>
    if console?.log? and @logging()
      console.log arguments...

  logging: (level) =>
    !!@_log_level

  startLogging: (level) =>
    @_log_level = level ? 'info'

  stopLogging: (level) =>
    @_log_level = null
