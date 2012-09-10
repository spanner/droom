module Droom
  class Group < ActiveRecord::Base

    belongs_to :created_by, :class_name => 'User'
    belongs_to :leader, :class_name => 'Person'

    has_many :memberships
    has_many :people, :through => :memberships, :uniq => true
  
    has_many :attachments, :as => :attachee
    has_many :documents, :through => :attachments
  
    named_scope :containing, lambda { |person|
      {
        :joins => "INNER JOIN memberships as mb on mb.group_id = groups.id", 
        :conditions => ["mb.person_id = ?", reader.id],
        :group => column_names.map { |n| 'groups.' + n }.join(',')
      }
    }
  
    def admit(person)
      self.readers << reader
    end

    def membership_for(person)
      self.memberships.for(person).first
    end
  
  end
end