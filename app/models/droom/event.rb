require 'uuidtools'
require 'chronic'

module Droom
  class Event < ActiveRecord::Base
    attr_accessible :start, :finish, :name, :description, :event_set_id, :created_by_id, :uuid, :all_day, :master_id, :url, :start_date, :start_time, :finish_date, :finish_time, :venue

    belongs_to :created_by, :class_name => 'User'

    has_many :invitations
    has_many :users, :through => :invitations

    has_many :attachments, :as => :attachee
    has_many :documents, :through => :attachments
  
    belongs_to :venue
    accepts_nested_attributes_for :venue

    belongs_to :event_set
    accepts_nested_attributes_for :event_set
  
    belongs_to :master, :class_name => 'Event'
    has_many :occurrences, :class_name => 'Event', :foreign_key => 'master_id', :dependent => :destroy
    has_many :recurrence_rules, :dependent => :destroy, :conditions => {:active => true}
    accepts_nested_attributes_for :recurrence_rules, :allow_destroy => true

    validates :start, :presence => true, :date => true
    validates :finish, :date => {:after => :start, :allow_nil => true}
    validates :uuid, :presence => true, :uniqueness => true
    validates :name, :presence => true

    before_validation :set_uuid
    after_save :update_occurrences
  
    default_scope :order => 'start ASC', :include => :venue
    scope :primary, { :conditions => "master_id IS NULL" }
    scope :recurrent, { :conditions => "master_id IS NOT NULL" }
  
    ## Event retrieval in various ways
    #
    # All of these methods return scopes.
    #
  
    scope :after, lambda { |datetime| # datetime. eg calendar.occurrences.after(Time.now)
      where(['start > ?', datetime])
    }
  
    scope :before, lambda { |datetime| # datetime. eg calendar.occurrences.before(Time.now)
      where(['start < ?', datetime])
    }
  
    scope :within, lambda { |period| # CalendarPeriod object
      where(['start > :start AND start < :finish', {:start => period.start, :finish => period.finish}])
    }

    scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
      where(['start > :start AND start < :finish', {:start => start, :finish => finish}])
    }
  
    scope :future_and_current, lambda {
      where(['(finish > :now) OR (finish IS NULL AND start > :now)', {:now => Time.now}])
    }
  
    scope :unfinished, lambda { |start| # datetimable object.
      where(['start < :start AND finish > :start', {:start => start}])
    }
    
    scope :by_finish, order("finish ASC")
  
    scope :coincident_with, lambda { |start, finish| # datetimable objects.
      where(['(start < :finish AND finish > :start) OR (finish IS NULL AND start > :start AND start < :finish)', {:start => start, :finish => finish}])
    }

    scope :limited_to, lambda { |limit|
      limit(limit)
    }
  
    scope :at_venue, lambda { |venue| # EventVenue object
      where(["venue_id = ?", venue.id])
    }
  
    scope :except_these, lambda { |uuids| # array of uuid strings
      placeholders = uuids.map{'?'}.join(',')
      where(["uuid NOT IN (#{placeholders})", *uuids])
    }

    def self.in_the_last(period)           # seconds. eg calendar.occurrences.in_the_last(1.week)
      finish = Time.now
      start = finish - period
      between(start, finish)
    end

    def self.in_year(year)                 # just a number. eg calendar.occurrences.in_year(2010)
      start = DateTime.civil(year)
      finish = start + 1.year
      between(start, finish)
    end

    def self.in_month(year, month)          # numbers. eg calendar.occurrences.in_month(2010, 12)
      start = DateTime.civil(year, month)
      finish = start + 1.month
      between(start, finish)
    end
  
    def self.in_week(year, week)            # numbers, with a commercial week: eg calendar.occurrences.in_week(2010, 35)
      start = DateTime.commercial(year, week)
      finish = start + 1.week
      between(start, finish)
    end
  
    def self.on_day (year, month, day)      # numbers: eg calendar.occurrences.on_day(2010, 12, 12)
      start = DateTime.civil(year, month, day)
      finish = start + 1.day
      between(start, finish)
    end

    def self.future
      after(Time.now)
    end

    def self.past
      before(Time.now)
    end

    ## Instance methods
    #    
    # We store the start and end points of the event as a single DateTime value to make comparison simple.
    # The setters for date and time are overridden to pass strings through chronic's natural language parser
    # and to treat numbers as epoch seconds. These should all work as you'd expect:
    #
    #   event.start = "Tuesday at 11pm"
    #   event.start = "12/12/1969 at 10pm"
    #   event.start = "1347354111"
    #   event.start = Time.now + 1.hour
    #
    def start=(value)
      write_attribute :start, parse_date(value)
    end

    def finish=(value)
      write_attribute :finish, parse_date(value)
    end
    
    # For interface purposes we often want to separate date and time parts. These getters will return the 
    # corresponding Date or Time object.
    #
    # The `time_of_day` gem makes time handling a bit more intuitive by concealing the date part of a Time object.
    #
    def start_time
      start.time_of_day if start
    end

    def start_date
      start.to_date if start
    end
    
    def finish_time
      finish.time_of_day if finish
    end

    def finish_date
      finish.to_date if finish
    end
    
    # And these setters will adjust the current value so that its date or time part corresponds to the given
    # value. The value is passed through the same parsing mechanism as above, so:
    #
    #   event.start = "Tuesday at 11pm"       -> next Tuesday at 11pm
    #   event.start_time = "8pm"              -> next Tuesday at 8pm
    #   event.start_date = "Wednesday"        -> next Wednesday at 8pm
    #   event.start_date = "26 February 2016" -> 26/2/16 at 8pm
    #   event.start_time = "18:00"            -> 26/2/16 at 6pm
    #
    # If the time is set before the date, we default to that time today. Times default to 00:00 in the usual way.
    #
    def start_time=(value)
      self.start = (start_date || Date.today).to_time + parse_date(value).seconds_since_midnight
    end
    
    def start_date=(value)
      self.start = parse_date(value).to_date# + start_time
    end
  
    def finish_time=(value)
      self.finish = (finish_date || start_date || Date.today).to_time + parse_date(value).seconds_since_midnight
    end
    
    def finish_date=(value)
      self.finish = parse_date(value).to_date# + finish_time
    end



    def duration
      if finish
        finish - start
      else
        0
      end
    end

    def one_day?
      all_day? && within_day?
    end
  
    def within_day?
      (!finish || start.to.jd == finish.to.jd || finish == start + 1.day)
    end
  
    def continuing?
      finish && start < Time.now && finish > Time.now
    end

    def finished?
      start < Time.now && (!finish || finish < Time.now)
    end
  
    def recurs?
      master || occurrences.any?
    end
  
    def recurrence
      recurrence_rules.first.to_s
    end
  
    def add_recurrence(rule)
      self.recurrence_rules << Droom::RecurrenceRule.from(rule)
    end




    def as_ri_cal_event
      RiCal.Event do |cal_event|
        cal_event.uid = uuid
        cal_event.summary = name
        cal_event.description = description if description
        cal_event.dtstart =  (all_day? ? start_date : start) if start
        cal_event.dtend = (all_day? ? finish_date : finish) if finish
        cal_event.url = url if url
        cal_event.rrules = recurrence_rules.map(&:to_ical) if recurrence_rules.any?
        cal_event.location = venue.name if venue
      end
    end
  
    def to_ical
      as_ri_cal_event.to_s
    end
  



  protected

    def set_uuid
      self.uuid = UUIDTools::UUID.timestamp_create.to_s if uuid.blank?
    end

    # doesn't yet observe exceptions
    def update_occurrences
      occurrences.destroy_all
      if recurrence_rules.any?
        recurrence_horizon = Time.now + 10.years
        as_ri_cal_event.occurrences(:before => recurrence_horizon).each do |occ|
          occurrences.create!({
            :name => self.name,
            :url => self.url,
            :description => self.description,
            :venue => self.venue,
            :start => occ.dtstart,
            :finish => occ.dtend,
            :uuid => nil
          }) unless occ.dtstart == self.start
        end
      end
    end

    def parse_date(value)
      case value
      when Numeric
        Time.at(value)
      when String
        Chronic.parse(value)
      else
        value
      end
    end
  
  end
end