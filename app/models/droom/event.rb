require 'open-uri'
require 'zip/zip'
require 'uuidtools'
require 'chronic'
require 'ri_cal'

module Droom
  class Event < ActiveRecord::Base
    attr_accessible :start, :finish, :name, :description, :event_set_id, :created_by_id, :uuid, :all_day, :master_id, :url, :start_date, :start_time, :finish_date, :finish_time, :venue, :private, :public, :venue_name

    belongs_to :created_by, :class_name => 'User'

    has_many :invitations, :dependent => :destroy
    has_many :people, :through => :invitations

    has_many :group_invitations, :dependent => :destroy
    has_many :groups, :through => :group_invitations

    has_many :document_attachments, :as => :attachee, :dependent => :destroy
    has_many :documents, :through => :document_attachments

    has_many :agenda_categories, :dependent => :destroy
    has_many :categories, :through => :agenda_categories
  
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
    before_save :check_slug
    after_save :update_occurrences
  
    scope :primary, where("master_id IS NULL")
    scope :recurrent, where(:conditions => "master_id IS NOT NULL")
    default_scope order('start ASC').includes(:venue)
  
    ## Event retrieval in various ways
    #
    # All of these methods return scopes.
    #
    scope :after, lambda { |datetime| # datetime. eg calendar.occurrences.after(Time.now)
      where(['start > ?', datetime])
    }
  
    scope :before, lambda { |datetime| # datetime. eg calendar.occurrences.before(Time.now)
      where(['start < :date AND (finish IS NULL or finish < :date)', :date => datetime])
    }
  
    scope :between, lambda { |start, finish| # datetimable objects. eg. Event.between(reader.last_login, Time.now)
      where(['start > :start AND start < :finish AND (finish IS NULL or finish < :finish)', :start => start, :finish => finish])
    }
  
    scope :future_and_current, lambda {
      where(['(finish > :now) OR (finish IS NULL AND start > :now)', :now => Time.now])
    }
  
    scope :unfinished, lambda { |start| # datetimable object.
      where(['start < :start AND finish > :start', :start => start])
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
  
    scope :except_these_uuids, lambda { |uuids| # array of uuid strings
      placeholders = uuids.map{'?'}.join(',')
      where(["uuid NOT IN (#{placeholders})", *uuids])
    }
    
    scope :without_invitations_to, lambda { |person| # Person object
      select("droom_events.*")
        .joins("LEFT OUTER JOIN droom_invitations ON droom_events.id = droom_invitations.event_id AND droom_invitations.person_id = #{sanitize(person.id)}")
        .group("droom_events.id")
        .having("COUNT(droom_invitations.id) = 0")
    }
    
    scope :all_private, where("private = 1 OR private = 't'")
    scope :not_private, where("private = 0 OR private = 'f'")
    scope :all_public, where("public = 1 OR public = 't'")
    scope :not_public, where("public = 0 OR public = 'f'")

    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_events.name like ?', fragment)
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
    
    def self.in_span(span)                  # Chronic::Span
      between(span.begin, span.end)
    end

    def self.falling_within(span)           # Chronic::Span
      coincident_with(span.begin, span.end)
    end

    def self.future
      after(Time.now)
    end

    def self.past
      before(Time.now)
    end

    ## Instance methods
    #
    def identifier
      'event'
    end
    
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

    def venue_name
      venue.name if venue
    end
    
    def venue_name=(name)
      self.venue = Droom::Venue.find_or_create_by_name(name)
    end

    # Agenda sections are global, and we don't want to have to manage the extra workload of associating a section with an event.
    # This call retrieves all the agenda sections that are associated with any of our document attachments, and is suitable for looping
    # on a template to display attachments per section.
    #
    def agenda_sections
      Droom::AgendaSection.associated_with_event(self)
    end
    
    # and this sorts our attachment list into agenda section buckets so that we don't have to go back to the database for each section.
    def attachments_by_category
      cats = {}
      document_attachments.each_with_object({}) do |att, hash|
        key = att.category_name
        cats[key] ||= []
        cats[key].push(att)
      end
      categories.each do |category|
        key = category.name
        cats[key] ||= []
      end
      cats
    end
    
    def categories_for_selection
      cats = categories.map{|c| [c.name, c.id] }
      cats.unshift(['', ''])
      cats
    end
    
    def visible_to?(user_or_person)
      return true if self.public?
      return false unless user_or_person
      return true if user_or_person.admin?
      return true if user_or_person.person.invited_to?(self)
      return false if self.private?
      return true
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
    
    def documents_zipped
      if self.documents.any?
        tempfile = Tempfile.new("droom-temp-#{slug}-#{Time.now}.zip")
        Zip::ZipOutputStream.open(tempfile.path) do |z|
          self.documents.each do |doc|
            z.add(doc.file_file_name, open(doc.file.url))
          end
        end
        tempfile
      end
    end

    def to_rical
      RiCal.Event do |cal_event|
        cal_event.uid = uuid
        cal_event.summary = name
        cal_event.description = description if description
        cal_event.dtstart =  (all_day? ? start_date : start) if start
        cal_event.dtend = (all_day? ? finish_date : finish) if finish
        cal_event.url = url if url
        cal_event.rrules = recurrence_rules.map(&:to_rical) if recurrence_rules.any?
        cal_event.location = venue.name if venue
      end
    end
  
    def to_ics
      to_rical.to_s
    end

  protected
  
    def check_slug
      ensure_presence_and_uniqueness_of(:slug, "#{start.strftime("%Y %m %d")} #{name}".parameterize)
    end
    
    def set_uuid
      self.uuid = UUIDTools::UUID.timestamp_create.to_s if uuid.blank?
    end

    # doesn't yet observe exceptions
    def update_occurrences
      occurrences.destroy_all
      if recurrence_rules.any?
        recurrence_horizon = Time.now + 10.years
        to_rical.occurrences(:before => recurrence_horizon).each do |occ|
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