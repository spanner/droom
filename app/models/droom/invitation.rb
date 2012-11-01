module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
        
    belongs_to :person
    belongs_to :event
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

    after_create :link_documents
    after_destroy :remove_document_links

    validates_uniqueness_of :person_id, :scope => [:event_id, :group_invitation_id]

  protected
  
    def link_documents
      person.documents << event.documents
    end
    
    def remove_document_links
      person.documents -= event.documents
    end

  end
end