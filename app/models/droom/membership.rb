module Droom
  class Membership < ActiveRecord::Base
    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"
    
    after_save :update_personal_documents
    after_delete :update_personal_documents
    
  protected
  
    def update_personal_documents
      People.each do |person|
        person.send :update_personal_documents
      end
    end

  end
end