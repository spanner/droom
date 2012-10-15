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
      @_events = point.events
      @_postcode = point.postcode      
      @id = point.id
      @_name = point.name
      @_address = point.address
      @_editable = $.ed
      @_marker = new google.maps.Marker
        position: new google.maps.LatLng @_lat, @_lng
        map: @_map
        icon: $.set_icon(@_events.length)
        draggable: $.map_editable
      @infowindow()
      google.maps.event.addListener @_marker, "click", @click
      google.maps.event.addListener @_marker, "dragstart", @dragstart
      google.maps.event.addListener @_marker, "dragend", @dragend
      @_infowindow.open(@_map) if parseInt($.urlParam("id"), 10) == @id
      
      
    infowindow: () =>
      content = $("<div class='window'><h2>#{@_name}</h2>#{@_address.replace(/\n/g, ",")}<div class='window_venue_events'></div></div>")
      $.each @_events, (i, evt) =>
        content.find('.window_venue_events').append "<li><a href='/events/#{evt.id}'>#{evt.name}</a> <span class='pale'>#{evt.datestring}</span></li>"
      @_infowindow = new google.maps.InfoWindow
        position: new google.maps.LatLng @_lat, @_lng
        content: content.prop('outerHTML')
        marker: @_marker
      $.infowindows.push @_infowindow

    click: (e) =>
      $.each $.infowindows, (i, iw) =>
        iw.close()
      @_infowindow.open(@_map)
      
    dragstart: (e) =>
      @_infowindow?.close()

    dragend: (e) =>
      position = @_marker.getPosition()
      $.ajax 
        type: 'POST'
        url: "/venues/#{@id}",
        data: 
          _method: "PUT"
          venue:
            lat: position.lat()
            lng: position.lng()
        dataType: 'json'
        success: () ->
          console.log "venue updated"
        

  $.fn.init_map = () ->
    @each ->
      $.gmap = new Map(@).getMap()
      $.map_editable = $(@).hasClass('editable')
      if $(@).hasClass('small')
        $(@).show_venue()
      else
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
          
          temporary_zoom_limiter = google.maps.event.addListener map, 'bounds_changed', ->
            map.setZoom(17) if map.getZoom() > 17
            google.maps.event.removeListener(temporary_zoom_limiter);

          map.fitBounds bounds

  $.fn.show_venue = () ->
    @each ->
      map = $.gmap
      if src = $(@).attr("data-url")
        $.getJSON src, (venue) =>
          latlng = new google.maps.LatLng venue.lat, venue.lng
          marker = new google.maps.Marker
            position: latlng
            map: map
            icon: $.set_icon(venue.events.length)
          map.setCenter(latlng)


  $.urlParam = (name) ->
    results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(window.location.href)
    return 0  unless results
    results[1] or 0

  $.set_icon = (size) ->
    name = if size > 0 then "place_busy" else "place_quiet"
    new google.maps.MarkerImage "/assets/droom/#{name}.png", new google.maps.Size(36, 36), new google.maps.Point(0, 0), new google.maps.Point(18, 18)
  
