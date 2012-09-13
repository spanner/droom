module Droom
  class Invitation < ActiveRecord::Base
    belongs_to :person
    belongs_to :event
    belongs_to :created_by, :class_name => "User"

    after_create :create_personal_documents
    after_delete :remove_personal_documents
    
  protected
  
    def create_personal_documents
      person.send :update_personal_documents
    end
  
    def remove_personal_documents
      person.send :update_personal_documents
    end

  end
end