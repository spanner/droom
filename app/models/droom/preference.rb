# Preferences...

module Droom
  class Preference < ApplicationRecord
    belongs_to :created_by, :class_name => "Droom::User"
    validates :key, :presence => true, :uniqueness => {:scope => :created_by_id}
    
    def set(value)
      if boolean?
        self.value = value ? 1 : 0
      else
        self.value = value
      end
      self.save if changed?
    end
    
    def get
      if boolean?
        value.to_i == 1
      else
        value
      end
    end
    
    def boolean?
      key.last == "?"
    end
    
    def uuid
      self[:uuid] ||= SecureRandom.uuid
    end
  
  end
end