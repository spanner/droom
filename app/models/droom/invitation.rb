module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
        
    belongs_to :person
    belongs_to :event
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

    after_create :link_folder
    after_destroy :unlink_folder

    validates_uniqueness_of :person_id, :scope => [:event_id, :group_invitation_id]

    scope :to_event, lambda { |event|
      where(["event_id = ?", event.id])
    }
    
    scope :for_person, lambda { |person|
      where("droom_invitations.person_id = ?", person.id)
    }
    
    scope :future, lambda {
      select('droom_invitations.*')
        .joins('inner join droom_events as de on droom_invitations.event_id = de.id')
        .where(['de.start > :now', :now => Time.now])
        .group('droom_invitations.id')
    }
    
    scope :refused, where("response < 1")
    scope :accepted, where("response > 1")
    scope :not_refused, where("response > 0")
    scope :not_accepted, where("response < 2")
    scope :responded, where("response <> 1")
    scope :not_responded, where("response == 1")
  
    def link_folder
      person.add_personal_folders(event.folder)
    end
    
    def unlink_folder
      person.remove_personal_folders(event.folder)
    end
    
    def status
      if response < 1
        "rejected"
      elsif response == 1
        "maybe"
      else
        "accepted"
      end
    end
    
    def accepted?
      response && response > 1
    end

    def rejected?
      response && response < 1
    end
    
  end
  
end