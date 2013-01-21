closestPointOnALineBetween = (a, b, c) ->
  a_x = a.lat
  a_y = a.lng
  b_x = b.lat
  b_y = b.lng
  c_x = c.lat
  c_y = c.lng
  u = ((a_x - b_x) * (c_x - b_x) + (a_y - b_y) * (c_y - b_y)) / (Math.pow((c_x - b_x), 2) + Math.pow((c_y - b_y), 2))
  if u > 0.95
    v = 1
  else if u < 0.05
    v = 0
  else
    v = u
  t_x = b_x + v * (c_x - b_x)
  t_y = b_y + v * (c_y - b_y)
  {lat: t_x, lng: t_y}

closestPointOnPolyline = (point, path) ->
  len = path.length()
  e_array = []
  t_array = []
  i = 0
  while i < len - 1
    b = p[i]
    c = p[i+1]
    t = closestPointOnALineBetween(point, b, c)
    e = distanceToPoint(point, t)
    e_array.push e
    t_array.push t
    i++
  t_array.getAt e_array.indexOf(e_array.min())

indexOfClosestPointOnPolyline = (point, path) ->
  len = path.length()
  e_array = []
  i = 0
  while i < len - 1
    b = p[i]
    c = p[i + 1]
    t = closestPointOnALineBetween(point, b, c)
    e = distanceToPoint(point, t)
    e_array.push e
    i++
  e_array.indexOf(e_array.min()) + 1

distanceToPoint = (a, t) ->
  a_x = a.lat
  a_y = a.lng
  t_x = t.lat
  t_y = t.lng
  Math.pow (Math.pow((a_x - t_x), 2) + Math.pow((a_y - t_y), 2)), 0.5    

