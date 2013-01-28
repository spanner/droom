# Preferences...

module Droom
  class Preference < ActiveRecord::Base
    attr_accessible :key, :value
    belongs_to :created_by, :class_name => "Droom::User"
    validates :key, :presence => true, :uniqueness => true
    
    def set(value)
      self.value = value
      self.save if changed?
    end
    
    def get
      value
    end
    
  end
end