class ScorePicker
  constructor: (element) ->
    @_field = $(element)
    @_container = $('<div class="starpicker" />')
    @_value = @_field.val()
    @_value = 
    for i in [1..5]
      do (i) =>
        star = $('<span class="star" />')
        star.attr('data-score', i)
        star.bind "mouseover", (e) =>
          @hover(e, star)
        star.bind "mouseout", (e) =>
          @unhover(e, star)
        star.bind "click", (e) =>
          @set(e, star)
        @_container.append star
    @_stars = @_container.find('span.star')
    @_field.after(@_container)
    @_field.hide()

  hover: (e, star) =>
    @unhover()
    i = parseInt(star.attr('data-score'))
    @_stars.slice(0, i).addClass('hovered')
    
  unhover: (e, star) =>
    @_stars.removeClass('hovered')

  set: (e, star) =>
    e.preventDefault if e
    @unhover()
    i = parseInt(star.attr('data-score'))
    @_stars.removeClass('selected')
    @_stars.slice(0, i).addClass('selected')
    @_field.val(i)


$.fn.score_picker = () ->
  @each ->
    new ScorePicker @
    

class ScoreShower
  constructor: (element) ->
    @_container = $(element)
    @_rating = parseFloat(@_container.text(), 10)
    @_rating ||= 0
    @_bar = $('<div class="starbar" />').appendTo(@_container)
    @_mask = $('<div class="starmask" />').appendTo(@_container)
    @_bar.css
      width: @_rating/5 * 80

$.fn.star_rating = () ->
  @each ->
    new ScoreShower @
