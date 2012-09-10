module Droom
  class Venue < ActiveRecord::Base

    belongs_to :created_by, :class_name => 'User'
    has_many :events, :dependent => :nullify
    acts_as_mappable

    default_scope :order => 'title asc'
    before_validation :geocode_location

    def to_s
      title
    end
    
    def as_json(options={})
      json = {
        :title => title,
        :postcode => postcode,
        :lat => lat,
        :lng => lng,
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