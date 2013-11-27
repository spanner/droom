module Droom
  class Category < ActiveRecord::Base
    include Droom::Concerns::Slugged

    belongs_to :created_by, :class_name => "Droom::User"
    has_many :document_attachments
    
    before_validation :slug_from_name
    validates :slug, :presence => true, :uniqueness => true
    
    default_scope -> { order("droom_categories.name ASC") }
        
    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      self.all.map{|c| [c.name, c.id] }
    end

  end
end
