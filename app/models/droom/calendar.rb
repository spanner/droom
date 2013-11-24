module Droom
  class Calendar < ActiveRecord::Base
    include Slugged
    
    belongs_to :created_by, :class_name => "Droom::User"
    has_many :events

    before_validation :slug_from_name
    validates :slug, :presence => true, :uniqueness => true
    
    def self.for_selection
      self.all.map{|c| [c.name, c.id] }
    end

  end
end
