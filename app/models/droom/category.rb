module Droom
  class Category < ActiveRecord::Base
    attr_accessible :name, :description, :slug
    
    belongs_to :created_by, :class_name => "Droom::User"
    has_many :document_attachments
    
    before_validation :ensure_slug
    validates :slug, :presence => true, :uniqueness => true
    
    default_scope order("droom_categories.name ASC")
        
    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      categories = self.all.map{|c| [c.name, c.id] }
      categories.unshift(['', ''])
      categories
    end

  protected
  
    def ensure_slug
      ensure_presence_and_uniqueness_of(:slug, name.parameterize)
    end

  end
end
