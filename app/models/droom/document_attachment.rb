module Droom
  class DocumentAttachment < ActiveRecord::Base
    attr_accessible :attachee, :document, :agenda_section, :category_id
    
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :category
    belongs_to :created_by, :class_name => "User"

    has_many :document_links, :dependent => :destroy
    has_many :people, :through => :document_links

    after_destroy :remove_private_document_if_unattached
    after_create :link_people

    default_scope order("(CASE WHEN droom_document_attachments.category_id IS NULL THEN 0 ELSE 1 END), droom_documents.updated_at ASC, droom_documents.created_at ASC").includes(:document)
        
    scope :unfiled, where("category_id IS NULL")

    scope :attached_to, lambda { |attachee| 
      where(["droom_document_attachments.attachee_type = :class AND droom_document_attachments.attachee_id = :id", :class => attachee.class.to_s, :id => attachee.id])
    }

    scope :to_event, lambda { |event| 
      where(["droom_document_attachments.attachee_type = 'Droom::Event' AND droom_document_attachments.attachee_id = ?", event.id])
    }

    scope :to_group, lambda { |group| 
      where(["droom_document_attachments.attachee_type = 'Droom::Group' AND droom_document_attachments.attachee_id = ?", group.id])
    }

    scope :to_events, lambda { |events| 
      placeholders = events.map{'?'}.join(',')
      ids = events.map(&:id)
      where(["droom_document_attachments.attachee_type = 'Droom::Event' AND droom_document_attachments.attachee_id IN (#{placeholders})", *ids])
    }

    scope :to_groups, lambda { |groups| 
      placeholders = groups.map{'?'}.join(',')
      ids = groups.map(&:id)
      where(["droom_document_attachments.attachee_type = 'Droom::Group' AND droom_document_attachments.attachee_id IN (#{placeholders})", *ids])
    }
    
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
  
  protected
  
    def remove_private_document_if_unattached
      unless document.public? || document.document_attachments.count > 0
        document.destroy
      end
    end
    
    # Upon creation we create document links to all the people who are newly entitled to see the document.
    # Deletion takes care of itself, as document_links are :dependent => :destroy.
    #
    def link_people
      people << attachee.people if attachee
    end
  end
end