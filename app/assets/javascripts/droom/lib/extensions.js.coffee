# Return the last item in an array.

unless Array::last?
  Array::last = () ->
    @[@.length - 1]

# Return the first item in an array.

unless Array::first?
  Array::first = () ->
    @[0]

# Return the (mathematically) greatest item in an array.

unless Array::max?
  Array::max = () ->
    Math.max.apply Math, this      

# Return the (mathematically) least item in an array.

unless Array::min?
  Array::min = () ->
    Math.min.apply Math, this

# Return true if this array contains any items

unless Array::any?
  Array::any = ()->
    @length > 0

# Return true unless this array contains any items

unless Array::empty?
  Array::empty = ()->
    @length == 0

# Removes one instance of the supplied thing from an array

unless Array::remove?
  Array::remove = (thing)->
    @splice(@indexOf(thing), 1)

# Return this array as a sentence in the form "x, y and z".

unless Array::toSentence?
  Array::toSentence = ()->
    @join(", ").replace(/,\s([^,]+)$/, ' and $1')

# Truncate a string to the specified number of characters. Add an ellipsis if shortening actually happens.

unless String::truncate?
  String::truncate = (length, separator, ellipsis)->
    length ?= 100
    ellipsis ?='...'
    if @length > length
      trimmed = @substr 0, length - ellipsis.length
      trimmed = trimmed.substr(0, trimmed.lastIndexOf(separator)) if separator? 
      trimmed + '...'
    else
      @

# Remove leading and trailing spaces from a string. Unavailable before JS1.5.

unless String::trim?
  String::trim = (length, separator, ellipsis)->
    String(@).replace(/^\s+|\s+$/g, '')
    
