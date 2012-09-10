module Droom
  class Group < ActiveRecord::Base

    belongs_to :created_by, :class_name => 'User'
    belongs_to :leader, :class_name => 'Person'

    has_many :memberships
    has_many :people, :through => :memberships, :uniq => true
  
    has_many :attachments, :as => :attachee
    has_many :documents, :through => :attachments
  
    def admit(person)
      self.readers << reader
    end

    def membership_for(person)
      self.memberships.for(person).first
    end
  
  end
end