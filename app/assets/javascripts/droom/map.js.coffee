jQuery ($) ->
  $.infowindows = []
  
  class Map
    constructor: (element) ->
      @_container = $(element)
      @_editable = @_container.hasClass('editable')
      @_infowindows = []
      lat = @_container.attr('data-lat') || 22.280147
      lng = @_container.attr('data-lng') || 114.158302
      zoom = @_container.attr('data-zoom') || 12
      @_bounds = new google.maps.LatLngBounds()
      @_map = new google.maps.Map element,
        center: new google.maps.LatLng lat, lng
        zoom: parseInt(zoom)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        mapTypeControlOptions: 
          style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
    getMap: () =>
      @_map

    isEditable: () =>
      @_editable
      
    getBounds: () =>
      @_bounds
      
    setBounds: (things) =>
      @_bounds = new google.maps.LatLngBounds()
      for thing in things
        if pos = thing.getPosition()
          @_bounds.extend(pos) 
      @showBounds()

    extendBounds: (position) =>
      if position
        @_bounds.extend(position)
        @showBounds()
    
    showBounds: () =>
      @_zoom_limiter = google.maps.event.addListener @_map, 'bounds_changed', =>
        @_map.setZoom(17) if @_map.getZoom() > 17
        google.maps.event.removeListener(@_zoom_limiter);
      @_map.fitBounds @_bounds

    rememberInfowindow: (iw) =>
      @_infowindows.push(iw)

    closeInfowindows: (iw) =>
      iw.close() for iw in @_infowindows


  class VenueMap extends Map
    constructor: (element) ->
      super
      @_venues = []
      if @container.hasClass('small')
        @get_one_venue()
      else
        @get_venues()
    
    get_one_venue: () =>
      if src = @container.attr("data-url")
        $.getJSON src, @show_venue
      
    get_venues: () =>
      if src = @container.attr("data-url")
        $.getJSON src, @show_venues

    show_venues: (response) =>
      @show_venue(venue) for venue in response

    show_venue: (response) =>
      latlng = new google.maps.LatLng response.lat, response.lng
      venue = new Venue response, @
      @_venues.push venue
      @extendBounds(venue)




  class Venue
    constructor: (point, @_map) ->
      @_lat = point.lat
      @_lng = point.lng
      @_events = point.events
      @_postcode = point.postcode
      @id = point.id
      @_name = point.name
      @_address = point.address
      @_marker = new google.maps.Marker
        position: new google.maps.LatLng @_lat, @_lng
        map: @_map
        draggable: @_map.isEditable()
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
      $.gmap = new VenueMap(@).getMap()
    @


  $.set_icon = (size) ->
    name = if size > 0 then "place_busy" else "place_quiet"
    new google.maps.MarkerImage "/assets/droom/#{name}.png", new google.maps.Size(36, 36), new google.maps.Point(0, 0), new google.maps.Point(18, 18)
  
  
  $.namespace "Droom", (target, top) ->
    target.Map = Map
    target.VenueMap = VenueMap
    target.Venue = Venue
