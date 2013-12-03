class Array
  def to_ics
    to_icalendar.to_ical
  end
  
  def to_icalendar
    cal = Icalendar::Calendar.new
    self.flatten.each do |item|
      cal.add_event(item.icalendar_event) if item.respond_to? :icalendar_event
    end
    cal
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

