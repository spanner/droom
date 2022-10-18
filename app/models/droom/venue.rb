module Droom
  class Venue < Droom::DroomRecord
    include Droom::Concerns::Slugged
    include Droom::Concerns::Suggested

    belongs_to :created_by, optional: true, class_name: "Droom::User"
    has_many :events, :dependent => :nullify

    before_validation :slug_from_name
    # for migration purposes only:
    # reverse_geocoded_by :lat, :lng, :address => :address
    # after_validation :reverse_geocode

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_venues.name like ?', fragment)
    }
    
    scope :in_name_order, -> {
      order('name ASC')
    }
    
    default_scope -> {order('name ASC')}

    def self.visible_to(user=nil)
      self.scoped({})
    end

    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      self.all.map{|v| [v.proper_name, v.id] }
    end

    def definite_name
      if prepend_article?
        "the #{name}"
      else
        name
      end
    end

    def to_s
      name
    end

    def identifier
      'venue'
    end

    def name_and_address
      [name, address, post_code].compact.join("\n")
    end

    def as_json(options={})
      json = {
        type: "droom/venue",
        id: id,
        name: name,
        postcode: post_code,
        address: address.to_s,
        lat: lat,
        lng: lng
      }
    end

    def as_ri_cal_calendar
      RiCal.Calendar do |cal|
        events.primary.each do |event|
          cal.add_subcomponent(event.to_ri_cal)
        end
      end
    end

    def to_ical
      self.as_ri_cal_calendar.to_s
    end

    ## Search
    #
    searchkick callbacks: :async, _all: false, default_fields: [:name, :address, :postcode], word_start: [:name, :address, :postcode]

    def search_data
      data = {
        id: id,
        type: "droom/venue",
        name: name,
        postcode: post_code,
        address: address,
      }
      if lat? && lng?
        data[:loc] = {
          lon: lng,
          lat: lat
        }
      end
      data
    end

  end
end