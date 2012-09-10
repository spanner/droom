module Droom
  class Period
    attr_writer :start, :finish
    
    PositiveInfinity = +1.0/0.0
    
    def self.between(from=nil,to=nil)
      raise DroomError, "Droom::Period.between requires either start or finish datetime" unless from || to
      period = self.new
      period.start = from
      period.finish = to
      period
    end
  
    def self.from(from, duration=nil)
      to = from + duration if duration
      between(from, to)
    end
  
    def self.to(to, duration=nil)
      from = to - duration if duration
      between(from, to)
    end
  
    def self.default
      between(Time.now, nil)
    end
  
    def default?
      finish.nil? && (Time.now - start).to_i.abs < 1.minute
    end
  
    def start
      @start.to_datetime if @start
    end

    def finish
      @finish.to_datetime if @finish
    end
  
    def duration
      if bounded?
        finish - start
      else
        PositiveInfinity
      end
    end
    
    def duration=(s)
      if start
        finish = start + s
      elsif finish
        start = finish - s
      end
    end
  
    def bounded?
      start && finish
    end
  
    def unbounded?
      !bounded?
    end
      
    # to expand the period to full calendar months
    # @period.pad!
  
    def pad!
      start = start.beginning_of_month if start
      finish = finish.end_of_month if finish
    end

    # to shift the period forward one month
    # @period += 1.month

    def +(s)
      start = start + s if start
      finish = finish + s if finish
    end
  
    # to shift the period back one month
    # @period -= 1.month
  
    def -(s)
      start = start - s if start
      finish = finish - s if finish
    end
  
    # to extend the period by one month
    # @period << 1.month
  
    def <<(s)
      if bounded?
        finish += s
      else
        duration = s
      end
    end
  
  end

end