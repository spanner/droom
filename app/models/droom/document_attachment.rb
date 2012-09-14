module Droom
  class DocumentAttachment < ActiveRecord::Base
    attr_accessible :attachee, :document
    
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :created_by, :class_name => "User"
    has_many :personal_documents, :dependent => :destroy
    
    scope :not_personal_for, lambda {|person|
      select("droom_document_attachments.*").joins("LEFT OUTER JOIN droom_personal_documents ON droom_personal_documents.document_attachment_id = droom_document_attachments.id").where(["droom_personal_documents.person_id = ?", person.id]).group_by("droom_document_attachments.id").where("COUNT(droom_personal_documents.id) = 0")
    }
    
    def slug
      if attachee 
        attachee.slug
      else
        'unattached'
      end
    end
    
  end
end