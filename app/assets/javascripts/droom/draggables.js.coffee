jQuery ($) ->

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



$.fn.drag_manager = ->
  @each ->
    new DragManager(@)

class DragManager
  constructor: (element) ->
    @_container = $(element)
    @draggables = @_container.find('.draggable')
    manager = @
    @draggables.on 'mousedown', (e) -> manager.possibleDrag(e, @)
    # @draggables.on 'click', (e) -> $(@).removeClass('splash').addClass('splash')

  possibleDrag: (e, el) =>
    e.preventDefault()
    @el = $(el)
    @clone = undefined
    @origin = @el.position()
    @click =
      x: e.pageX
      y: e.pageY
    @startListening()

  dragMove: (e) =>
    e.preventDefault()
    dx = e.pageX - @click.x
    dy = e.pageY - @click.y
    if Math.sqrt(dy**2 + dx**2) > 5
      unless @clone?
        @clone = @el.clone().addClass('cloned dragging').appendTo @_container
        @clone.attr 'id', @el.attr('id') + "_dragging"
      pos = 
        left: @origin.left + dx
        top: @origin.top + dy
        width: @el.width()
        height: @el.height()
      @clone.css pos
      @el.addClass('dragged')
      @clone.show()
    else
      @clone?.hide()
      @el.removeClass('dragged')

  possibleDrop: (e) =>
    @stopListening()
    merging = false
    if @del and @confirmDrop(@del)
      @enactDrop(@del, @el).done(@dropSuccess).fail(@dropFail)
      merging = true
    unless merging or !@clone
      @showNodrop()

  # children will know what to check
  confirmDrop: (del=@del) =>
    false

  # children will know what to do.
  # must return promise.
  enactDrop: (droppee, dropped) =>
    # noop here

  # callback after failed enactDrop
  dropFail: (xhr, status, error) =>
    # noop here

  # callback after successful enactDrop
  dropSuccess: (response) =>
    @showDrop()

  showDrop: =>
    if @del
      destination = @del.offset()
      flyto =
        left: destination.left + @del.width() / 2
        top: destination.top + @del.height() / 2
        width: 0
        height: 0
        opacity: 0
      @clone.animate flyto, 250, 'glide', =>
        @del.removeClass("splash droppable").addClass("splash")
        del = @del
        window.setTimeout =>
          @el.remove()
          @del.addClass("pending")
          @reset()
        , 250
        window.setTimeout =>
          del?.refresh()
        , 10000

  showNodrop: =>
    if @clone and @origin
      flyback = _.extend @origin,
        opacity: 0
      @clone.removeClass 'dragging' # css transitioned
      @clone.animate flyback, 400, 'boing', @reset

  droppable: (e) =>
    @del = $(e.originalEvent.currentTarget)
    @del.addClass('droppable')

  undroppable: (e) =>
    @del?.removeClass('droppable')
    @del = null

  reset: =>
    @clone?.remove()
    @draggables.removeClass('dragged droppable')
    @el = null
    @del = null
    @clone = null
    @origin = null
    @click = null

  startListening: =>
    $(document)
      .on "mousemove", @dragMove
      .on "mouseup", @possibleDrop
    @draggables
      .on "mouseenter", @droppable
      .on "mouseleave", @undroppable

  stopListening: =>
    $(document)
      .off "mousemove", @dragMove
      .off "mouseup", @possibleDrop
    @draggables
      .off "mouseenter", @droppable
      .off "mouseleave", @undroppable


$.fn.user_merger = ->
  @each ->
    new UserMerger(@)

class UserMerger extends DragManager

  confirmDrop: (del=@del) =>
    console.log "confirmDrop:", @el, @del
    outer_item = @del.data('user')
    outer_name = @del.find('span.name').text()
    inner_item = @el.data('user')
    inner_name = @el.find('span.name').text()
    outer_item isnt inner_item and confirm("Really merge #{inner_name} (##{inner_item}) into #{outer_name} (##{outer_item})?")

  enactDrop: (droppee, dropped) =>
    outer_id = droppee.data('user')
    inner_id = dropped.data('user')
    url = "/users/#{outer_id}/subsume/#{inner_id}.json"
    $.ajax
      url: url
      method: "PUT"

  # callback after failed enactDrop
  dropFail: (xhr, status, error) =>
    @del?.signal_error()
    @showNodrop()






