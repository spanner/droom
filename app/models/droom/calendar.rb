module Droom
  class Calendar < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"

    before_save :ensure_slug

    has_many :events
    
    def self.for_selection
      self.all.map{|c| [c.name, c.id] }
    end

    def ensure_slug
      ensure_presence_and_uniqueness_of(:slug, name.parameterize)
    end

  end
end
