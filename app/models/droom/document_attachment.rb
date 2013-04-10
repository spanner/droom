module Droom
  class DocumentAttachment < ActiveRecord::Base
    attr_accessible :attachee, :document, :agenda_section, :category_id
    
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :category
    belongs_to :created_by, :class_name => "Droom::User"

    def slug
      if attachee 
        attachee.slug
      else
        'Unattached'
      end
    end
    
    def category_name
      category ? category.name : "uncategorised"
    end
  
    def move_document_to_folder
      recipient = if category
        # attachee will be an event
        attachee.find_or_create_agenda_category(category)
      else
        attachee
      end
      if document
        document.folder = nil
        recipient.receive_document(document)
        document.save
      end
    end
  
  end
end