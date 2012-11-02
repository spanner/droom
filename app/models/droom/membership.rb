module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    after_create :link_documents
    after_destroy :unlink_documents

    scope :of_group, lambda { |group|
      where(["group_id = ?", group.id])
    }

  protected
  
    def link_documents
      person.document_attachments << group.document_attachments
    end
  
    def unlink_documents
      person.document_attachments -= group.document_attachments
    end

  end
end