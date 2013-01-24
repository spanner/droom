class Array
  def to_ics
    to_rical.to_s
  end
  
  def to_rical
    RiCal.Calendar do |cal|
      self.flatten.each do |item|
        cal.add_subcomponent(item.to_rical) if item.respond_to?(:to_rical)
      end
    end
  end
end

class Hash
  def deep_set(path, value)
    keys = path.is_a?(Array) ? path : path.to_s.split(':')
    key = keys.shift
    if keys.empty?
      self[key.to_sym] = value
    else
      self[key.to_sym] ||= {}
      self[key.to_sym].deep_set(keys, value)
    end
  end
end