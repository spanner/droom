require 'snail'

module Droom
  class Venue < ActiveRecord::Base
    attr_accessible :name, :lat, :lng, :post_line1, :post_line2, :post_city, :post_country, :post_code
    
    belongs_to :created_by, :class_name => 'User'
    has_many :events, :dependent => :nullify
    acts_as_mappable

    default_scope :order => 'name asc'
    before_validation :geocode_and_get_address

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
      )
    end

    def address?
      post_line1? && post_city
    end

    def as_json(options={})
      json = {
        :id => id,
        :name => name,
        :postcode => post_code,
        :address => address.to_s,
        :lat => lat,
        :lng => lng,
        :events => events.as_json({})
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

    # We only go back to google for a new map location if there has been a change of address, but there are many places in which that could happen.
    #
    def address_changed?
      name_changed? || post_line1_changed? || post_line2_changed? || post_city_changed? || post_region_changed?  || post_code_changed? || post_country_changed?
    end

  private

    # This is the main geocoding routine, called before validation on every save. If there has been a significant change, 
    # it will trigger the goecoding mechanism with a block that updates our address when a match is found. 
    # It's fairly uncritical and probably needs to be more careful about overriding user-entered data.
    #
    def geocode_and_get_address(options={})
      unless Rails.env.test?
        if new_record? || address_changed? || options[:force]
          geocode_with(:name) do |geo|
            self.post_line1 = geo.street_address
            self.post_city = geo.city
            self.post_region = geo.province
            self.post_country = geo.country
            self.post_code = geo.zip
            sleep(options[:delay].seconds) if options[:delay]
          end
        end
      end
    end

    # *geocode_with* does the actual lookup, passing the value of the specified column to the google geocoder service (with help from Geokit)
    # and yielding to the supplied block as soon as a match is found.
    #
    def geocode_with(attribute, &block)
      value = send(attribute)
      found = false
      unless value.blank?
        geo = Geokit::Geocoders::GoogleGeocoder3.geocode(value, :bias => Droom.geocode_bias, :language => 'en')
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