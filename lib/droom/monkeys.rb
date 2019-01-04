module ActiveRecord
  class Base
    # Not truly random but never mind. It picks an unpredictable record.
    def self.sample
      offset(rand(count)).first
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

