require 'snail'

module Droom
  class Venue < ActiveRecord::Base
    attr_accessible :name, :post_line1, :post_line2, :post_city, :post_country
    
    belongs_to :created_by, :class_name => 'User'
    has_many :events, :dependent => :nullify
    acts_as_mappable

    default_scope :order => 'name asc'
    before_validation :geocode_location

    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_venues.name like ?', fragment)
    }

    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      self.all.map{|v| [v.proper_name, v.id] }
    end

    def proper_name
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
    
    # Snail is a library that abstracts away - as far as possible - the vagaries of international address formats. Here we map our data columns onto Snail's abstract representations so that they can be rendered into the correct format for their country.
    def address
      Snail.new(
        :line_1 => post_line1,
        :line_2 => post_line2,
        :city => post_city,
        :region => post_region,
        :postal_code => post_code,
        :country => post_country
      ).to_s
    end

    def address?
      post_line1? && post_city
    end

    
    def as_json(options={})
      json = {
        :id => id,
        :name => name,
        :postcode => post_code,
        :lat => lat,
        :lng => lng
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

  private

    #todo this should give priority to postcodes, then addresses, then names
    #
    def geocode_location
    
    end

    # *geocode* will try all the possible geocode bases in order until it gets a result. If a block is given, it is passed through.
    #
    def geocode(&block)
      geocode_with(:name, &block) || geocode_with(:postal_address, &block)
    end

    # *geocode_with* does the actual lookup, passing the value of the specified column to the google geocoder service (with help from Geokit)
    # and yielding to the supplied block as soon as a match is found.
    #
    def geocode_with(attribute, &block)
      value = send(attribute)
      found = false
      unless value.blank?
        geo = Geokit::Geocoders::GoogleGeocoder3.geocode(value, :bias => 'hk', :language => 'en')
        if geo.success
          self.lat, self.lng = geo.lat, geo.lng
          yield geo if block_given?
          found = true
        end
      end
      found
    end

  end
end