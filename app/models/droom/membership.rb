module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    after_create :link_folder
    after_destroy :unlink_folder

    scope :of_group, lambda { |group|
      where(["group_id = ?", group.id])
    }

    def current?
      expires == nil or expires > Time.now
    end
  
    def set_expiry(date)
      unless expires and expires > date
        self.expires = date
        save!
      end
    end

  protected

    def link_documents
      person.document_attachments << group.document_attachments
    end
    
    def link_folder
      person.add_personal_folders(group.folder)
    end

    def unlink_documents
      person.document_attachments -= group.document_attachments
    end

  end
end
