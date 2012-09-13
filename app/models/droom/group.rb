module Droom
  class Group < ActiveRecord::Base

    belongs_to :created_by, :class_name => 'User'
    belongs_to :leader, :class_name => 'Person'

    has_many :memberships
    has_many :people, :through => :memberships, :uniq => true
  
    has_many :attachments, :as => :attachee
    has_many :documents, :through => :attachments
  
    before_save :check_slug
  
    def admit(person)
      self.readers << reader
    end

    def membership_for(person)
      self.memberships.for(person).first
    end
  
  protected
  
    def check_slug
      ensure_presence_and_uniqueness_of(:slug, name)
    end
  end
end