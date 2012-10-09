module Droom
  class Category < ActiveRecord::Base
    attr_accessible :name, :description
    
    belongs_to :created_by, :class_name => 'User'
    has_many :document_attachments
    
    default_scope order("droom_categories.name ASC")
        
    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      categories = self.all.map{|c| [c.name, c.id] }
      categories.unshift(['', ''])
      categories
    end
    
  end
end
