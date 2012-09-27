module Droom
  class DocumentAttachment < ActiveRecord::Base
    attr_accessible :attachee, :document, :agenda_section
    
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :agenda_section
    belongs_to :created_by, :class_name => "User"
    has_many :personal_documents, :dependent => :destroy
    
    default_scope order("(CASE WHEN droom_document_attachments.agenda_section_id IS NULL THEN 0 ELSE 1 END)").includes(:document)
    
    scope :not_personal_for, lambda {|person|
      select("droom_document_attachments.*")
        .joins("LEFT OUTER JOIN droom_personal_documents ON droom_personal_documents.document_attachment_id = droom_document_attachments.id")
        .where(["droom_personal_documents.person_id = ?", person.id])
        .group("droom_document_attachments.id")
        .having("COUNT(droom_personal_documents.id) = 0")
    }
    
    scope :unfiled, where("agenda_section_id IS NULL")
    
    def slug
      if attachee 
        attachee.slug
      else
        'Unattached'
      end
    end
    
    def create_or_update_personal_document_for(person)
      if pd = personal_documents.belonging_to(person)
        pd.reclone_if_changed
      else 
        personal_documents.create(:person => person)
      end
    end
  
  end
end