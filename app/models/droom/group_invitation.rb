module Droom
  class GroupInvitation < ActiveRecord::Base
    attr_accessible :event_id, :group_id
    
    belongs_to :group
    belongs_to :event
    has_many :invitations, :dependent => :destroy
    belongs_to :created_by, :class_name => "User"
    after_create :create_personal_invitations
    validates_uniqueness_of :group_id, :scope => :event_id
    
    scope :to_event, lambda { |event|
      where("group_invitations.event_id = ?", event.id)
    }
    
    def create_personal_invitations
      group.people.each do |person|
        invitations.find_or_create_by_person_id_and_event_id(person.id, event.id)
      end
    end
    
  end
end