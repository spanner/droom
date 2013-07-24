module Droom
  class GroupInvitation < ActiveRecord::Base
    belongs_to :created_by, :class_name => "User"
    belongs_to :group
    belongs_to :event
    has_many :invitations, :dependent => :destroy
    after_save :create_personal_invitations
    validates_uniqueness_of :group_id, :scope => :event_id
    
    scope :to_event, lambda { |event|
      where("droom_group_invitations.event_id = ?", event.id)
    }
    
    scope :for_group, lambda { |group|
      where("droom_group_invitations.group_id = ?", group.id)
    }
    
    def create_personal_invitations
      group.users.each do |user|
        create_personal_invitation_for(user)
      end
    end

    def create_personal_invitation_for(user)
      invitations.where(:user_id => user.id, :event_id => event.id).first_or_create
    end

  end
end