module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    after_create :link_documents
    after_destroy :remove_document_links

  protected
  
    def link_documents
      person.documents << group.documents if person
    end
    
    def remove_document_links
      person.documents -= group.documents if person
    end

  end
end