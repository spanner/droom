module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
        
    belongs_to :person
    belongs_to :event
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

    after_create :link_documents
    after_destroy :unlink_documents

    validates_uniqueness_of :person_id, :scope => [:event_id, :group_invitation_id]

    scope :to_event, lambda { |event|
      where(["event_id = ?", event.id])
    }

  protected
  
    def link_documents
      person.document_attachments << event.document_attachments
    end
    
    def unlink_documents
      person.document_attachments -= event.document_attachments
    end

  end
end