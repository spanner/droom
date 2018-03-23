# Preferences...

module Droom
  class Preference < ApplicationRecord
    belongs_to :created_by, :class_name => "Droom::User"
    validates :key, :presence => true, :uniqueness => {:scope => :created_by_id}
    after_save :poke_user

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

    protected

    def poke_user
      if created_by && created_by.respond_to?(user_callback)
        created_by.send(user_callback)
      end
    end

    def user_callback
      callable_key = key.gsub('.', '_').to_param
      "after_change_#{callable_key}_preference".to_sym
    end

  end
end