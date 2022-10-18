module Droom
  class Event < Droom::DroomRecord
    include Droom::Concerns::Slugged
    include Droom::Concerns::Suggested
    include ActionView::Helpers::SanitizeHelper

    belongs_to :created_by, optional: true, class_name: "Droom::User"

    belongs_to :calendar
    belongs_to :event_type

    belongs_to :venue, optional: true
    accepts_nested_attributes_for :venue

    belongs_to :event_set, optional: true
    accepts_nested_attributes_for :event_set

    has_many :scraps

    has_folder :within => :event_type
    after_destroy :destroy_related_folder

    validates :start, :presence => true, :date => true
    validates :finish, :date => {:after => :start, :allow_nil => true}
    validates :uuid, :presence => true, :uniqueness => true
    validates :name, :presence => true
    validates :event_type_id, :presence => true

    before_validation :set_uuid
    before_validation :slug_from_name_and_year
    before_validation :set_default_event_type

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

    scope :future_and_current, -> { where(['(finish > :now) OR (finish IS NULL AND start > :now)', :now => Time.zone.now]) }

    scope :finished, -> { where(['(finish < :now) OR (finish IS NULL AND start < :now)', :now => Time.zone.now]) }
    
    scope :unbegun, -> { where(['start > :now', :now => Time.zone.now])}

    scope :by_finish, -> { order("finish ASC") }

    scope :by_date, -> { order("start ASC") }

    scope :by_date_descending, -> { order("start DESC, finish DESC") }

    scope :coincident_with, -> start, finish { where(['(start < :finish AND finish >= :start) OR (finish IS NULL AND start >= :start AND start < :finish)', {:start => start, :finish => finish}]) }

    scope :at_venue, -> venue { where(:venue_id => venue.id) }

    scope :of_type, -> event_type { where(:event_type_id => event_type.id) }

    scope :in_calendar, -> calendar { where(:calendar_id => calendar.id) }

    scope :added_since, -> date { where("created_at > ?", date)}

    scope :except_these_uuids, -> uuids {
      placeholders = uuids.map{'?'}.join(',')
      where(["uuid NOT IN (#{placeholders})", *uuids])
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
      finish = Time.zone.now
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
    #   event.start = Time.zone.now + 1.hour
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
    # The `tod` gem makes time handling a bit more intuitive by concealing the date part of a Time object.
    #
    
    def start
      tz = timezone || Time.zone
      if start = read_attribute(:start)
        start.in_time_zone(tz)
      end
    end
    
    def start_time
      Tod::TimeOfDay(start) if start
    end

    def start_date
      start.to_date if start
    end

    def start_datetime
      if start?
        start_time.on(start_date)
      elsif start_date
        start_date.start_of_day
      end
    end

    def finish
      tz = timezone || Time.zone
      if finish = read_attribute(:finish)
        finish.in_time_zone(tz)
      end
    end

    def finish_time
      Tod::TimeOfDay(finish) if finish
    end

    def finish_date
      finish.to_date if finish
    end

    def finish_datetime
      if finish?
        finish_time.on(finish_date)
      elsif finish_date
        finish_date.end_of_day
      end
    end

    def month
      start.strftime("%m")
    end

    def month_name
      start.strftime("%b")
    end

    def year
      start.strftime("%Y")
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
      self.venue = Droom::Venue.where(name: name).first_or_create
    end

    def confidential?
      private? || event_type && event_type.confidential?
    end

    def visible_to?(user)
      return true if self.public?
      return true if user.privileged?
      return false if self.confidential?# || Droom.events_private_by_default?
      return true
    end
    
    def detail_visible_to?(user)
      return true if self.public?
      return false unless user
      return true if user.admin?
      return false if self.private?
      return true
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
      finish && start < Time.zone.now && finish > Time.zone.now
    end

    def finished?
      start < Time.zone.now && (!finish || finish < Time.zone.now)
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

    def plain_description
      strip_tags(description)
    end

    def icalendar_event
      event = Icalendar::Event.new
      event.uid = uuid
      event.summary = name
      event.description = plain_description if description?
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

    def folder_name
      "#{name} (#{month_name} #{year})"
    end

    ## Search
    #
    searchkick callbacks: :async

    def search_data
      {
        type: "droom/event",
        id: id,
        name: name,
        slug: slug,
        venue_name: venue_name,
        date: start_datetime
      }
    end

    def venue_name
      venue.name if venue
    end

    protected

    # This is mostly for ical/webcal distributions but we also use it in the API.
    #
    def set_uuid
      self.uuid = UUIDTools::UUID.timestamp_create.to_s if uuid.blank?
    end

    def set_default_event_type
      self.event_type ||= Droom::EventType.default
    end

    def parse_date(value)
      case value
      when Numeric
        Time.at(value)
      when String
        Time.zone.parse(value)
      else
        value
      end
    end

    private

    def destroy_related_folder
      if event_folder = self.folder
        event_folder.destroy
      end
    end

  end
end