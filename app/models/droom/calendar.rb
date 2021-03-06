module Droom
  class Calendar < ActiveRecord::Base
    include Droom::Concerns::Slugged
    
    belongs_to :created_by, :class_name => "Droom::User"
    has_many :events

    before_validation :slug_from_name
    validates :slug, :presence => true, :uniqueness => true
    
    def self.for_selection
      self.all.map{|c| [c.name, c.id] }
    end
    
    def self.default_calendar
      where(:name => "main").first_or_create
    end
    
    def self.stream_calendar
      where(:name => "stream").first_or_create
    end

  end
end
