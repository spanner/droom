module Droom
  class Attachment < ActiveRecord::Base
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :created_by, :class_name => "User"
    has_many :personal_documents
    
    scope :not_personal_for, lambda {|person|
      select("droom_attachments.*").join("LEFT OUTER JOIN droom_personal_documents ON droom_personal_documents.attachment_id = droom_attachments.id").where(["droom_personal_documents.person_id = ?", person.id]).group_by("droom_attachments.id").where("COUNT(droom_personal_documents.id) = 0")
    }
    
    def slug
      attachee.slug
    end
    
  end
end