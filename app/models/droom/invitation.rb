module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
    
    belongs_to :person
    belongs_to :event
    belongs_to :created_by, :class_name => "User"

    after_create :create_personal_documents
    after_destroy :remove_personal_documents
    
  protected
  
    # This shouldn't be _too_expensive but still ought to be delayed.
    def create_personal_documents
      person.send :gather_documents_from, event
    end
  
    def remove_personal_documents
      
    end

  end
end