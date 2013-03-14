jQuery ($) ->
  $.infowindows = []
  
  class Map
    constructor: (element) ->
      @_container = $(element)
      @_editable = @_container.hasClass('editable')
      @_infowindows = []
      @_affected = @_container.attr('data-affected')
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
      if @_container.hasClass('small')
        @get_one_venue()
      else
        @get_venues()
    
    get_one_venue: () =>
      if src = @_container.attr("data-url")
        $.getJSON src, @show_venue
      
    get_venues: () =>
      if src = @_container.attr("data-url")
        $.getJSON src, @show_venues

    show_venues: (response) =>
      @show_venue(venue) for venue in response

    show_venue: (response) =>
      latlng = new google.maps.LatLng response.lat, response.lng
      venue = new Venue response, @
      @_venues.push venue


  class Venue
    constructor: (data, @_mapper) ->
      @_map = @_mapper.getMap()
      @id = data.id
      @_name = data.name
      @_address = data.address
      @_events = data.events
      @_postcode = data.postcode
      @_marker = new google.maps.Marker
        map: @_map
        draggable: @_mapper.isEditable()
      if data.lat? and data.lng?
        @_position = new google.maps.LatLng(data.lat, data.lng)
        @placeMarker()
      google.maps.event.addListener @_marker, "click", @show
      google.maps.event.addListener @_marker, "dragstart", @pickup
      google.maps.event.addListener @_marker, "dragend", @drop

    placeMarker: () =>
      @_marker.setPosition(@_position)
      @_mapper.extendBounds(@_position)

    getPosition: () =>
      @_position

    show: () =>
      @_mapper.closeInfowindows()
      @infowindow().open(@_map, @_marker)
    
    update: (e) =>
      # console.log "update", e.latLng

    infowindow: () =>
      unless @_infowindow?
        content = $("<div class='window'><h2>#{@_name}</h2>#{@_address.replace(/\n/g, ",")}<div class='window_venue_events'></div></div>")
        for evt in @_events
          content.find('.window_venue_events').append "<li><a href='/events/#{evt.id}'>#{evt.name}</a> <span class='pale'>#{evt.datestring}</span></li>"
        @_infowindow = new google.maps.InfoWindow
          content: content.prop('outerHTML')
          maxWidth: 300
        @_mapper.rememberInfowindow(@_infowindow)
      @_infowindow

    pickup: (e) =>
      @_infowindow?.close()

    drop: (e) =>
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
        
    remove: (e) =>
      e.preventDefault() if e
      @_infowindow?.close()
      @_marker.setMap(null)



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
