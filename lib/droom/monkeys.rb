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

