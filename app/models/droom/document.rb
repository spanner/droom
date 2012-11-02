module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file, :description, :attachment_category_id, :event_id

    # attachment_category and event_id are used on document creation to create an associated attachment
    # this is a temporary shortcut 
    attr_accessor :old_version, :attachment_category_id, :event_id

    belongs_to :created_by, :class_name => 'User'

    has_many :document_attachments, :dependent => :destroy
    has_many :document_links, :through => :document_attachments
    has_many :people, :through => :document_links
    
    has_attached_file :file
    
    before_save :set_version
    validates :file, :presence => true

    scope :all_private, where("private = 1 OR private = 't'")
    scope :not_private, where("NOT(private = 1 OR private = 't')")
    scope :all_public, where("public = 1 OR public = 't'")
    scope :not_public, where("NOT(public = 1 OR public = 't')")
    
    scope :visible_to, lambda { |person|
      select('droom_documents.*')
        .joins('LEFT OUTER JOIN droom_document_attachments ON droom_documents.id = droom_document_attachments.document_id')
        .joins('LEFT OUTER JOIN droom_document_links ON droom_document_attachments.id = droom_document_links.document_attachment_id')
        .where(["(droom_documents.public = 1 OR droom_document_links.person_id = ?)", person.id])
        .group('droom_documents.id')
    }
    
    scope :name_matching, lambda { |fragment|
      fragment = "%#{fragment}%"
      where('droom_documents.name like ?', fragment)
    }
    
    scope :attached_to_these_groups, lambda { |groups|
      placeholders = groups.map{'?'}.join(',')
      select('droom_documents.*')
        .joins('INNER JOIN droom_document_attachments ON droom_documents.id = droom_document_attachments.document_id AND droom_document_attachments.attachee_type = "Droom::Group"')
        .where(["droom_document_attachments.attachee_id IN(#{placeholders})", *groups.map(&:id)])
    }
    
    scope :with_latest_event, 
      select('droom_documents.*, droom_categories.name AS category_name, droom_events.id AS latest_event_id, droom_events.name AS latest_event_name')
        .joins('LEFT OUTER JOIN droom_document_attachments ON droom_documents.id = droom_document_attachments.document_id 
                LEFT OUTER JOIN droom_categories ON droom_document_attachments.category_id = droom_categories.id
                LEFT OUTER JOIN droom_events ON droom_document_attachments.attachee_id = droom_events.id AND droom_document_attachments.attachee_type = "Droom::Event"')
        .group('droom_documents.id')

    # so that we can apply the joined finders above to an existing object
    #
    scope :this_document, lambda { |doc|
      where(["droom_documents.id = ?", doc.id])
    }

    scope :by_date, order("droom_documents.updated_at ASC, droom_documents.created_at ASC")

    def identifier
      'document'
    end

    def file_ok?
      file.exists?
    end
    
    def attachment_category_id=(id)
      attach_to(Droom::Event.find(event_id), {:category_id => id})
    end

    def attach_to(attachee, attributes={})
      save!
      document_attachments.create(attributes.merge(:attachee => attachee))
    end
    
    def detach_from(attachee)
      document_attachments.attached_to(attachee).destroy_all
    end
    
    def file_extension
      if file_file_name
        File.extname(file_file_name).sub(/^\./, '')
      else
        ""
      end
    end
    
    def with_event
      self.class.this_document(self).with_latest_event.first
    end
    
  protected
    
    def set_version
      if file.dirty?
        self.version = (version || 0) + 1
      end
    end

  end
end
