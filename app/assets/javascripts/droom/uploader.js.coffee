jQuery ($) ->

  $.fn.droploader = ->
    @each ->
      new Droploader(@)


  class Droploader
    constructor: (element) ->
      @_catcher = $(element)
      @_active = true
      @_url = @_catcher.data('droppable')
      @_form = $('<form method="POST" class="droploader" />').addClass('uploader').insertAfter @_catcher
      @resetFilefield()
      if queue_selector = @_catcher.data('queue')
        @_queue = $(queue_selector)
      else
        @_queue = @_catcher.find('[data-role="upload-queue"]')
      if picker_selector = @_catcher.data('picker')
        @_triggers = $(picker_selector)
      else
        @_triggers = @_catcher.find('[data-role="upload-file"]')
      @_triggers.click @triggerFilefield
      @_readers = []
      @enable()
      @_catcher.on "sorting", @disable
      @_catcher.on "not_sorting", @enable
 
    enable: =>
      @_active = true
      @_catcher.on "dragenter", @lookAvailable
      @_catcher.on "drop", @catchFiles

    disable: =>
      @_active = false
      @_catcher.off "dragenter", @lookAvailable
      @_catcher.off "drop", @catchFiles
 
    resetFilefield: () =>
      @_filefield?.remove()
      @_filefield = $('<input type="file" multiple="multiple" />').appendTo(@_form)
      @_filefield.on "change", @readFilefield

    triggerFilefield: (e) =>
      e?.preventDefault()
      @_filefield.click()   # won't work in IE

    readFilefield: =>
      @readFiles @_filefield[0].files
      @resetFilefield()

    catchFiles: (e) =>
      @lookNormal()
      if e?.originalEvent.dataTransfer?.files.length
        @blockEvent(e)
        @readFiles e.originalEvent.dataTransfer.files
      else
        console.log "unreadable drop", e


    readFiles: (files) =>
      if files
        for file in files
          @uploadFile file

    uploadFile: (file) =>
      new Upload
        file: file
        queue: @_queue
        url: @_url
        callback: @finishUpload

    blockEvent: (e) =>
      e.preventDefault()
      e.stopPropagation()

    blockDragover: (e) =>
      e.preventDefault()
      if e.originalEvent.dataTransfer
        e.originalEvent.dataTransfer.dropEffect = 'copy'

    lookNormal: =>
      @_catcher.removeClass('droppable')

    lookAvailable: =>
      unless @_mask
        @_mask = $('<div class="dropmask" />').appendTo @_catcher
        @_mask.on "dragover", @blockDragover
        @_mask.on "drop", @catchFiles
        @_mask.on "dragleave", @lookNormal
      @_catcher.addClass('droppable')

    finishUpload: (upload, el) =>
      console.log "FINISHED", upload, el, @_catcher.data('refreshes')
      if target_selector = @_catcher.data('refreshes')
        $(target_selector).refresh()
      # else
      #   @_catcher.refresh()


# The Upload class handles our formdata packaging, XHR-submission and progress reporting.
# Unlike the other uploaders it supports multiple parallel uploads.
#
# 1. build progress list item
# 2. ajax upload to form action url
# 3. on completion, remove progress li and replace with returned link partial

class Upload
  constructor: (@_options) ->
    @_file = @_options.file
    @_queue = @_options.queue
    @_url = @_options.url
    @_callback = @_options.callback
    if @_file && @_url
      @readFile()
      @prepXhr()
      @prepProgress()
      @sendData()

  readFile: =>
    @_mime = @_file.type
    @_filename ?= @_file.name.split(/[\/\\]/).pop()
    @_ext = @_file.name.split('.').pop()

  prepXhr: =>
    @_xhr = new XMLHttpRequest()
    @_xhr.withCredentials = true
    @_xhr.upload.onprogress = @showProgress
    @_xhr.onreadystatechange = @stateChange
    @_xhr.open 'POST', @_url, true
    @_xhr.setRequestHeader('X-PJAX', 'true')
    if csrf_token = $('meta[name="csrf-token"]').attr('content')
      @_xhr.setRequestHeader('X-CSRF-Token', csrf_token )

  prepProgress: () =>
    @_li = $('<li class="uploading"></li>').addClass(@_ext).appendTo(@_queue)
    @_label_holder = $('<span class="label"></span>').appendTo @_li
    @_label = $('<span class="filename"></span>').text(@_filename).appendTo @_label_holder
    if @_mime.substr(0,5) is "image"
      thumbnail = $('<img class="thumbnail" />').prependTo @_label_holder
      @previewImage(thumbnail)
    else
      $('<span class="file" />').prependTo @_label_holder
    @_progress_holder = $('<span class="progress"></span>').appendTo @_li
    @_bar = $('<span class="bar"></span>').appendTo @_progress_holder
    @_canceller = $('<a class="cancel minimal"></a>').appendTo @_li
    @_waiter = $('<span class="waiting"></a>').appendTo @_li
    @_w = @_progress_holder.width()
    @_canceller.click @cancel

  previewImage: (img) =>
    console.log "previewImage in", img

  sendData: =>
    form_data = new FormData()
    form_data.append("document[name]", @_filename)
    form_data.append("document[file]", @_file)
    @_xhr.send(form_data)

  showProgress: (e) =>
    if e.lengthComputable
      prog = e.loaded / e.total
      @_bar.width Math.round(@_w * prog)
      if prog > 0.99
        @_li.addClass('waiting')

  stateChange: () =>
    if @_xhr.readyState == 4
      if @_xhr.status == 200
        @_bar.width @_w
        @success(@_xhr.responseText)
      else
        @error()

  success: (response) =>
    @_options.on_success?(response)
    confirmation = $(response)
    confirmation.activate()
    @_li.after confirmation
    @_li.remove()
    confirmation.signal_confirmation()
    @_callback?(this, confirmation)

  error: () =>
    console.log "error", @_xhr
    @_options.on_error?()
    @_li.addClass('erratic')
    @_li.append $('<span class="error" />').text(@_xhr.statusText)
    @_li.signal_error()

  cancel: () =>
    @_xhr.abort()
    @_options.on_cancel?()
    @_li.fadeOut () ->
      $(@).remove()



  $.fn.sortable_files = ->
    @each ->
      new SortableFiling(@)

  class SortableFiling
    constructor: (element) ->
      @_container = $(element)
      @_folder_id = @_container.data('folderId')
      @_droppables = @_container.parents('[data-droppable]')
      @_sortable = new Sortable element,
        group: "files"
        sort: true
        pull: true
        put: true
        revertClone: true
        onStart: @beginDrag
        onUpdate: @setPosition
        onAdd: @setPosition

    beginDrag: (e) =>
      console.log "beginDrag", @_droppables
      # @_droppables.trigger "sorting"
      $('[data-droppable]').trigger "sorting"

    setPosition: (e) =>
      $('[data-droppable]').trigger "not_sorting"
      $el = $(e.item || e.dragged)
      if doc_id = $el.data('docId')
        url = "/documents/#{doc_id}/reposition"
        params = document:
          position: e.newIndex + 1
          folder_id: @_folder_id
        update = $.ajax
          method: "PUT"
          url: url
          data: params
          success: ->
            $el.signal_confirmation()

    setParent: (e) =>
      console.log "setParent", e.item, e.from
      