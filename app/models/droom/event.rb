require 'open-uri'
require 'uuidtools'
require 'chronic'
require 'icalendar'
require 'date_validator'
require 'time_of_day'

module Droom
  class Event < ActiveRecord::Base

    belongs_to :created_by, :class_name => "Droom::User"

    has_folder #... and subfolders via agenda_categories

    has_many :invitations, :dependent => :destroy
    has_many :users, :through => :invitations

    has_many :group_invitations, :dependent => :destroy
    has_many :groups, :through => :group_invitations

    has_many :agenda_categories, :dependent => :destroy
    has_many :categories, :through => :agenda_categories

    belongs_to :venue
    accepts_nested_attributes_for :venue

    belongs_to :event_set
    accepts_nested_attributes_for :event_set

    belongs_to :calendar

    has_many :scraps

    validates :start, :presence => true, :date => true
    validates :finish, :date => {:after => :start, :allow_nil => true}
    validates :uuid, :presence => true, :uniqueness => true
    validates :name, :presence => true

    before_validation :set_uuid
    before_save :ensure_slug

    ## Event retrieval in various ways
    #
    # Events differ from other models in that they are visible to all unless marked 'private'.
    # The documents attached to them are only visible to all if marked 'public'.
    #
    scope :all_private, -> { where("private = 1") }
    scope :not_private, -> { where("private <> 1 OR private IS NULL") }
    scope :all_public, -> { where("public = 1 AND private <> 1 OR private IS NULL") }
    scope :not_public, -> { where("public <> 1 OR private = 1)") }

    scope :after, -> datetime { where(['start > ?', datetime]) }

    scope :before, -> datetime { where(['start < :date AND (finish IS NULL or finish < :date)', :date => datetime]) }

    scope :between, -> start, finish { where(['start > :start AND start < :finish AND (finish IS NULL or finish < :finish)', :start => start, :finish => finish]) }

    scope :future_and_current, -> { where(['(finish > :now) OR (finish IS NULL AND start > :now)', :now => Time.now]) }

    scope :finished, -> { where(['(finish < :now) OR (finish IS NULL AND start < :now)', :now => Time.now]) }
    
    scope :unbegun, -> { where(['start > :now', :now => Time.now])}

    scope :by_finish, -> { order("finish ASC") }

    scope :coincident_with, -> start, finish { where(['(start < :finish AND finish > :start) OR (finish IS NULL AND start > :start AND start < :finish)', {:start => start, :finish => finish}]) }

    scope :limited_to, -> limit { limit(limit) }

    scope :at_venue, -> venue { where(["venue_id = ?", venue.id]) }

    scope :except_these_uuids, -> uuids {
      placeholders = uuids.map{'?'}.join(',')
      where(["uuid NOT IN (#{placeholders})", *uuids])
    }

    scope :without_invitations_to, -> user {
      select("droom_events.*")
        .joins("LEFT OUTER JOIN droom_invitations ON droom_events.id = droom_invitations.event_id AND droom_invitations.user_id = #{sanitize(user.id)}")
        .group("droom_events.id")
        .having("COUNT(droom_invitations.id) = 0")
    }

    scope :with_documents, -> {
      select("droom_events.*")
        .joins("INNER JOIN droom_document_attachments ON droom_events.id = droom_document_attachments.attachee_id AND droom_document_attachments.attachee_type = 'Droom::Event'")
        .group("droom_events.id")
    }

    scope :matching, -> fragment { 
      fragment = "%#{fragment}%"
      where('droom_events.name like :f OR droom_events.description like :f', :f => fragment)
    }

    # All of these class methods also return scopes.
    #
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
      unbegun.order('start ASC')
    end

    def self.past
      finished.order('start DESC')
    end

    ## Instance methods
    #
    def invite(user)
      self.users << user
    end

    def attach(doc)
      self.documents << doc
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
      self.start = parse_date(value).to_date
    end

    def finish_time=(value)
      if value && !value.blank?
        time_portion = parse_date(value).seconds_since_midnight
        self.finish = (finish_date || start_date || Date.today).to_time + time_portion
      end
    end

    def finish_date=(value)
      self.finish = parse_date(value).to_date
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

    def find_or_create_agenda_category(category)
      agenda_categories.find_or_create_by_category_id(category.id)
    end
        
    def categories_for_selection
      cats = categories.map{|c| [c.name, c.id] }
      cats.unshift(['', ''])
      cats
    end

    def attended_by?(user)
      user && user.invited_to?(self)
    end

    def visible_to?(user)
      return true if self.public?
      return false if self.private?# || Droom.events_private_by_default?
      return true
    end
    
    def detail_visible_to?(user)
      return true if self.public?
      return false unless user
      return true if user.admin?
      return true if user.invited_to?(self)
      return false if self.private?
      return true
    end
    
    def has_anyone?
      invitations.any?
    end

    def has_documents?
      all_documents.any?
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
    
    def url_with_protocol
      if url? && url !~ /^https?:\/\//
        "http://#{url}"
      else
        url
      end
    end

    def url_without_protocol
      if url?
        url.sub(/^https?:\/\//, '')
      else
        ""
      end
    end

    def icalendar_event
      event = Icalendar::Event.new
      event.uid = uuid
      event.summary = name
      event.description = description if description?
      event.dtstart = (all_day? ? start_date : start) if start?
      event.dtend = (all_day? ? finish_date : finish) if finish?
      event.url = url_with_protocol if url?
      event.location = venue.name if venue
      event
    end

    def to_ics
      cal = Icalendar::Calendar.new
      cal.add_event(icalendar_event)
      cal.to_ical
    end

    def as_json(options={})
      json = super
      json[:datestring] = I18n.l start, :format => :natural_with_date
      json
    end

    def as_suggestion
      {
        :type => 'event',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def as_search_result
      {
        :type => 'event',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

  protected

    def ensure_slug
      ensure_presence_and_uniqueness_of(:slug, "#{start.strftime("%Y %m %d")} #{name}".parameterize)
    end

    def set_uuid
      self.uuid = UUIDTools::UUID.timestamp_create.to_s if uuid.blank?
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