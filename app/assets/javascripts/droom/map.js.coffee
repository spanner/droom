#= require droom/map_interface

jQuery ($) ->
  
  $.infowindows = []
  
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
      $.gmap = new Map.Gmap(@).getMap()
      $(@).show_venues()
  
  $.fn.show_venues = () ->
    @each ->
      map = $.gmap
      if src = $(@).attr("data-url")
        $.getJSON src, (response) =>
          bounds = new google.maps.LatLngBounds()
          $.each response, (i, venue) =>
            latlng = new google.maps.LatLng(venue.lat, venue.lng )
            bounds.extend latlng
            venue = new Point(venue, map)

          map.fitBounds(bounds)
