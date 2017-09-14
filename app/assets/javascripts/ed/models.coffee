class Ed.Model extends Backbone.Model
  savedAttributes: []

  initialize: ->
    @_loaded = $.Deferred()
    @build()
    @resetOriginalAttributes()
    @on 'sync', @resetOriginalAttributes
    @on "change", @changedIfSignificant

  build: =>
    #noop

  has: (attribute) =>
    !!@get(attribute)

  parse: (data) =>
    data = data.data if data.data
    attributes = _.extend data.attributes, id: data.id
    @readDates(attributes)
    attributes

  readDates: (data) =>
    for col in ["created_at", "updated_at", "published_at", "deleted_at"]
      if string = data[col]
        @set col, new Date(string)
        delete data[col]

  ## Change and save
  #
  # The main Editable model is delivered and saved as html on the page, but it will include
  # assets that need to be saved before they can be used. At the moment, only images and videos.
  # Each saveable asset defines a set of significant attributes to which any change means a save 
  # is required.
  #
  apiRoot: () =>
    @constructor.name.toLowerCase()

  saveIfChanged: =>
    @save() if @get('changed')

  changedIfSignificant: =>
    @set "changed", not _.isEmpty @significantChangedAttributes()

  significantChangedAttributes: () =>
    changed_keys = _.filter @savedAttributes, (k) =>
      not _.isEqual @get(k), @_original_attributes[k]
    _.pick @attributes, changed_keys

  resetOriginalAttributes: =>
    @_original_attributes = _.pick @attributes, @savedAttributes
    @set 'changed', false

  # rails-compatible JSON representation wrapped in root key.
  toJSON: =>
    root = @apiRoot()
    json = {}
    json[root] = {}
    if attributes = _.result @, "savedAttributes"
      for att in attributes
        getter = "get" + att.charAt(0).toUpperCase() + att.slice(1)
        json[root][att] = @[getter]?() ? @get(att)
    else
      json[root] = super
    json

  ## Progress job
  #
  # Each asset has its own save job that will be added to the jobs collection of its holding editable
  # and used to keep track of the overall status of the html block. Backbone.sync is overridden in the
  # application to call back to here with progress reports. Progress is usually displayed as a donut in
  # the asset view.
  #
  startProgress: (label="") =>
    @set("progress", 0.00)
    @set("progressing", true)
    @set("progress_label", label)
    if _ed.page
      @_job = _ed.page.startJob "#{label} #{@constructor.name}"
    else
      @_job = new Ed.Models.Job "#{label} #{@constructor.name}"

  setProgress: (p) =>
    if p.lengthComputable
      progress = p.loaded / p.total
      @set("progress", progress.toFixed(2))

  finishProgress: () =>
    @set("progress", 2.00)
    @set("progressing", false)
    @set("progress_label", "")
    @_job?.finish()
    @_job = null


class Ed.Collection extends Backbone.Collection


# The page object itself doesn't do much: most of the work here goes into managing its
# body property and collection of masthead images.
#
class Ed.Models.Editable extends Ed.Model
  defaults: 
    title: ""
    image_id: null
    content: "<p></p>"

  build: =>
    @_jobs = new Ed.Collections.Jobs
      holder: @
    @_jobs.on "add remove reset", @setBusyness

  # return a tidied version of our content with all editing machinery removed.
  getBody: =>
    content = $(@get('content'))
    content.find('[contenteditable], [contenteditable="false"]').removeAttr('contenteditable')
    content.find('[data-placeholder]').removeAttr('data-placeholder')
    content.find('.ed-buttons').remove()
    content.find('.ed-progress').remove()
    content.find('.ed-action').remove()
    $('<div />').append(content).html()

  startJob: (label) =>
    job = @_jobs.add
      label: label
    job.on "finished", =>
      @_jobs.remove(job)
    job

  setBusyness: () =>
    @set 'busy', !!@_jobs.length


## Images
# are uploaded on the side during editing.
#
class Ed.Models.Image extends Ed.Model
  savedAttributes: ["image", "image_name", "remote_url", "caption", "weighting"]

  build: =>
    @getThumb() if @isNew() and @has('image')

  getThumb: () =>
    unless @get('thumb_url')
      img = document.createElement('img')
      img.onload = =>
        @extractImage(img, 560)
      img.src = @get('image')

  extractImage: (img, w=48) =>
    unless @get('url')
      if img.height > img.width
        h = w * (img.height / img.width)
      else
        h = w
        w = h * (img.width / img.height)
      canvas = document.createElement('canvas')
      canvas.width = w
      canvas.height = h
      ctx = canvas.getContext('2d')
      ctx.drawImage(img, 0, 0, w, h)
      preview = canvas.toDataURL('image/png')
      @set "url", preview


class Ed.Collections.Images extends Backbone.Collection
  model: Ed.Models.Image
  url: "/api/images"


## Images
# are uploaded for inclusion but really ought to be picked from youtube.
#
class Ed.Models.Video extends Ed.Model
  savedAttributes: ["video", "video_name", "remote_url", "caption"]

  build: =>
    @getVideo() if @isNew() and @has('video')

  getVideo: () =>
    unless @has('thumb_url')
      vid = document.createElement('video')
      vid.onloadeddata = =>
        @extractImage(vid, 280)
      vid.src = @get('video')

  extractImage: (vid, w=48, t=0) =>
    unless @get('poster_url')
      if vid.videoHeight > vid.videoWidth
        h = w * (vid.videoHeight / vid.videoWidth)
      else
        h = w
        w = h * (vid.videoWidth / vid.videoHeight)
      vid.currentTime = t
      canvas = document.createElement('canvas')
      canvas.width = w
      canvas.height = h
      ctx = canvas.getContext('2d')
      ctx.drawImage(vid, 0, 0, w, h)
      preview = canvas.toDataURL('image/jpeg')
      @set "poster_url", preview


class Ed.Collections.Videos extends Backbone.Collection
  model: Ed.Models.Video
  url: "/api/videos"


## Minor inline assets
#
# These are not saved, but have their own existence so that a template can be bound and their positioning controlled.
#

class Ed.Models.Quote extends Ed.Model
  savedAttributes: []
  defaults:
    utterance: ""
    caption: ""


class Ed.Models.Button extends Ed.Model
  savedAttributes: []
  defaults:
    label: ""
    url: ""
    color: ""


## Notices
# are minimal on-screen remarks for confirmation or error-reporting.
# These are basic backbone models without our extra clutter.
#
class Ed.Models.Notice extends Backbone.Model
  savedAttributes: []
  defaults: 
    message: "Hi there."
    notice_type: "info"

  initialize: =>
    @set "created_at", new Date

  discard: =>
    @collection?.remove(@) or @destroy()


class Ed.Collections.Notices extends Ed.Collection
  model: Ed.Models.Notice
  comparator: "created_at"


# Jobs are just little busyness tokens that can have a progress value and go away when complete.
# Each Ed has a jobs collection and will refuse to save while jobs are busy.
# These are basic backbone models without our extra clutter.
#
class Ed.Models.Job extends Backbone.Model
  savedAttributes: []
  defaults: 
    status: "active"
    progress: 0
    completed: false

  finish: () =>
    @set("progress", 100)
    @set('completed', true)
    @trigger 'finished'

  setProgress: (p) =>
    if p.lengthComputable
      perc = Math.round(10000 * p.loaded / p.total) / 100.0
      @set("progress", perc)

  discard: () =>
    @collection?.remove(@) or @destroy()

class Ed.Collections.Jobs extends Backbone.Collection
  model: Ed.Models.Job

