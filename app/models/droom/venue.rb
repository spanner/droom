require 'snail'
require 'geocoder'

module Droom
  class Venue < ActiveRecord::Base
    include Droom::Concerns::Slugged

    belongs_to :created_by, :class_name => "Droom::User"
    has_many :events, :dependent => :nullify

    before_validation :slug_from_name

    geocoded_by :name_and_address, :latitude  => :lat, :longitude => :lng
    before_validation :geocode
    # reverse_geocoded_by :lat, :lng

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_venues.name like ?', fragment)
    }
    
    scope :in_name_order, -> {
      order('name ASC')
    }

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
    
    #todo: remove after migrations complete
    def postal_address
      Snail.new(
        :line_1 => post_line1,
        :line_2 => post_line2,
        :city => post_city,
        :region => post_region,
        :postal_code => post_code,
        :country => post_country
      )
    end
    
    def name_and_address
      [name, address, post_code].compact.join("\n")
    end




    def as_json(options={})
      json = {
        :id => id,
        :name => name,
        :postcode => post_code,
        :address => address.to_s,
        :lat => lat,
        :lng => lng
      }
    end

    def as_suggestion
      {
        :type => 'venue',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def as_search_result
      {
        :type => 'venue',
        :prompt => name,
        :value => name,
        :id => id
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

    def convert_gridref
      if post_code_changed?
        if post_code.is_gridref?
          self.lat, self.lng = post_code.to_latlng
        end
      end
    end
    
  end
end