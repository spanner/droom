module Droom
  class GroupInvitation < ActiveRecord::Base
    attr_accessible :event_id, :group_id
    
    belongs_to :created_by, :class_name => "User"
    belongs_to :group
    belongs_to :event
    has_many :invitations, :dependent => :destroy
    after_create :create_personal_invitations
    validates_uniqueness_of :group_id, :scope => :event_id
    
    scope :to_event, lambda { |event|
      where("droom_group_invitations.event_id = ?", event.id)
    }
    
    def create_personal_invitations
      group.people.each do |person|
        create_personal_invitation_for(person)
      end
    end

    def create_personal_invitation_for(person)
      invitations.find_or_create_by_person_id_and_event_id(person.id, event.id) if person.member_of?(group)
    end
    
  end
end