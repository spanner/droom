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

class Time
  def ceil(seconds = 60)
    Time.at((self.to_f / seconds).ceil * seconds)
  end

  def floor(seconds = 60)
    Time.at((self.to_f / seconds).floor * seconds)
  end
end

class DateTime
  def ceil(seconds = 60)
    Time.at(self.to_f).ceil(seconds).to_datetime
  end

  def floor(seconds = 60)
    Time.at(self.to_f).floor(seconds).to_datetime
  end
end

