jQuery ($) ->
  $.infowindows = []
  
  class Map
    constructor: (element) ->
      @container = $(element)
      lat = @container.attr('data-lat') || 22.280147
      lng = @container.attr('data-lng') || 114.158302
      zoom = @container.attr('data-zoom') || 12
      @map = new google.maps.Map element,
        center: new google.maps.LatLng lat, lng
        zoom: parseInt(zoom)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        mapTypeControlOptions: 
          style: google.maps.MapTypeControlStyle.DROPDOWN_MENU

    getMap: () =>
      @map  
  
  class Point
    constructor: (point, map) ->
      @_lat = point.lat
      @_lng = point.lng
      @_map = map
      @_postcode = point.postcode      
      @id = point.id
      @_name = point.name
      @_marker = new google.maps.Marker
        position: new google.maps.LatLng @_lat, @_lng
        map: @_map
      @infowindow()
      google.maps.event.addListener @_marker, "click", @click
      @_infowindow.open(@_map) if parseInt($.urlParam("id"), 10) == @id
      
    infowindow: () =>
      @_infowindow = new google.maps.InfoWindow
        position: new google.maps.LatLng @_lat, @_lng
        content: "<h2>#{@_name}</h2>"
        marker: @_marker
      $.infowindows.push @_infowindow

    click: () =>
      $.each $.infowindows, (i, iw) =>
        iw.close()
      @_infowindow.open(@_map)
      
  $.fn.init_map = () ->
    @each ->
      $.gmap = new Map(@).getMap()
      $(@).show_venues()
  
  $.fn.show_venues = () ->
    @each ->
      map = $.gmap
      if src = $(@).attr("data-url")
        $.getJSON src, (response) =>
          bounds = new google.maps.LatLngBounds()
          $.each response, (i, venue) =>
            latlng = new google.maps.LatLng venue.lat, venue.lng
            bounds.extend latlng
            venue = new Point venue, map

          map.fitBounds bounds

  $.urlParam = (name) ->
    results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(window.location.href)
    return 0  unless results
    results[1] or 0
