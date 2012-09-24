jQuery ($) ->

  class Map
    constructor: (element) ->
      @container = $(element)
      @container.show()
      lat = @container.attr('data-lat') || 54.497163
      lng = @container.attr('data-lng') || -3.040174
      zoom = @container.attr('data-zoom') || 12
      @map = new google.maps.Map element,
        center: new google.maps.LatLng lat, lng
        zoom: parseInt(zoom)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        zoomControlOptions: 
          position: google.maps.ControlPosition.RIGHT_TOP
        panControlOptions:
          position: google.maps.ControlPosition.RIGHT_TOP
        mapTypeControlOptions: 
          style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
      
    getMap: () =>
      @map
        
  $.fn.init_map = () ->
    @each ->
      $.gmap = new Map(@).getMap()

  $.namespace = (target, name, block) ->
    [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
    top = target
    target = target[item] or= {} for item in name.split '.'
    block target, top

  $.namespace "Map", (target, top) ->
    target.Gmap = Map

  $.urlParam = (name) ->
    results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(window.location.href)
    return 0  unless results
    results[1] or 0
