jQuery ($) ->

  $.fn.drag_sort = (options) ->
    @each ->
      first = 0
      offset = 1 + first
      sorter = $(@).sortable
        handle: ".handle"
      $.each $(@).children(), (i, child) =>
        $(child).bind "dragend", (e) =>
          child = $(child)
          index = child.index() + offset
          id = parseInt(child.attr('id').split("person_")[1], 10)
          $.ajax
            url: "/people/#{id}"
            type: "PUT"
            dataType: "JSON"
            data:
              person:
                position: index

    @
