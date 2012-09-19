module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file, :description
    attr_accessor :old_version

    belongs_to :created_by, :class_name => 'User'
    has_many :document_attachments, :dependent => :destroy
    has_many :personal_documents, :through => :document_attachments

    has_attached_file :file
    
    before_save :set_version
    after_update :refresh_personal_documents
    
    validates :file, :presence => true
    # default_scope order('updated_at DESC, created_at DESC')

    scope :all_private, where("private = 1 OR private = 't'")
    scope :not_private, where("NOT(private = 1 OR private = 't')")
    scope :all_public, where("public = 1 OR public = 't'")
    scope :not_public, where("NOT(public = 1 OR public = 't')")
    
    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_documents.name like ?', fragment)
    }
    
    scope :personal_and_public, lambda { |person|
      
    }
    
    scope :with_latest_event, 
      select('droom_documents.*, droom_events.id AS event_id, droom_events.name AS event_name')
        .joins('LEFT OUTER JOIN droom_document_attachments ON droom_documents.id = droom_document_attachments.document_id 
                INNER JOIN droom_events ON droom_document_attachments.attachee_id = droom_events.id AND droom_document_attachments.attachee_type = "Droom::Event"')
        .group('droom_documents.id')

    def identifier
      'document'
    end

    def file_ok?
      file.exists?
    end
    
    def attach_to(attachee)
      document_attachments.create(:attachee => attachee)
    end
    
    def file_extension
      File.extname(file_file_name).sub(/^\./, '')
    end
    
  protected
    
    def set_version
      if file.dirty?
        self.version = (version || 0) + 1
      end
    end
    
    # This is probably where we'll put the delay call
    def refresh_personal_documents
      if version_changed?
        self.personal_documents.each do |pd|
          pd.send :reclone_file
        end
      end
    end

  end
end
