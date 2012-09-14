module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file
    attr_accessor :old_version

    belongs_to :created_by, :class_name => 'User'
    has_many :document_attachments, :dependent => :destroy
    has_many :personal_documents, :through => :document_attachments

    has_attached_file :file
    
    before_save :set_version
    after_update :refresh_personal_documents
    
    validates :file, :presence => true
    default_scope order('updated_at DESC, created_at DESC')

    def file_ok?
      file.exists?
    end
    
    def attach_to(attachee)
      document_attachments.create(:attachee => attachee)
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
