require 'uuidtools'

module Droom
  class Event < ActiveRecord::Base
    attr_accessible :start_date, :end_date, :name, :description, :event_set_id, :created_by_id, :uuid, :all_day, :master_id, :url

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

    validates :start_date, :presence => true, :date => true
    validates :end_date, :date => {:after => :start_date}, :allow_nil => true
    validates :uuid, :presence => true, :uniqueness => true
    validates :name, :presence_unless_recurrence => true

    before_validation :set_uuid
    after_save :update_occurrences
  
    default_scope :order => 'start_date ASC', :include => :event_venue
    scope :primary, { :conditions => "master_id IS NULL" }
    scope :recurrent, { :conditions => "master_id IS NOT NULL" }
  
    ## Event retrieval in various ways
    #
    # All of these methods return scopes.
    #
  
    scope :after, lambda { |datetime| # datetime. eg calendar.occurrences.after(Time.now)
      where(['start_date > ?', datetime])
    }
  
    scope :before, lambda { |datetime| # datetime. eg calendar.occurrences.before(Time.now)
      where(['start_date < ?', datetime])
    }
  
    scope :within, lambda { |period| # CalendarPeriod object
      where(['start_date > :start AND start_date < :finish', {:start => period.start, :finish => period.finish}])
    }

    scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
      where(['start_date > :start AND start_date < :finish', {:start => start, :finish => finish}])
    }
  
    scope :future_and_current, lambda {
      where(['(end_date > :now) OR (end_date IS NULL AND start_date > :now)', {:now => Time.now}])
    }
  
    scope :unfinished, lambda { |start| # datetimable object.
      where(['start_date < :start AND end_date > :start', {:start => start}])
    }
  
    scope :coincident_with, lambda { |start, finish| # datetimable objects.
      where(['(start_date < :finish AND end_date > :start) OR (end_date IS NULL AND start_date > :start AND start_date < :finish)', {:start => start, :finish => finish}])
    }

    scope :limited_to, lambda { |limit|
      limit(limit)
    }
  
    scope :at_venue, lambda { |venue| # EventVenue object
      where(["event_venue_id = ?", venue.id])
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
  
    def duration
      if end_date
        end_date - start_date
      else
        0
      end
    end

    def one_day?
      all_day? && within_day?
    end
  
    def within_day?
      (!end_date || start_date.to_date.jd == end_date.to_date.jd || end_date == start_date + 1.day)
    end
  
    def continuing?
      end_date && start_date < Time.now && end_date > Time.now
    end

    def finished?
      start_date < Time.now && (!end_date || end_date < Time.now)
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
        cal_event.dtstart =  (all_day? ? start_date.to_date : start_date) if start_date
        cal_event.dtend = (all_day? ? end_date.to_date : end_date) if end_date
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
            :start_date => occ.dtstart,
            :end_date => occ.dtend,
            :uuid => nil
          }) unless occ.dtstart == self.start_date
        end
      end
    end
  
  end
end