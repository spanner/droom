module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"
    
    after_save :update_personal_documents
    after_destroy :update_personal_documents
    
  protected
  
    # This can be very expensive but should only happen rarely.
    def create_personal_documents
      attachables = [group] + group.events
      attachables.each do |attachee|
        person.send :gather_documents_from, attachee
      end
    end

  end
end