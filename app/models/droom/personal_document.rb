module Droom
  class PersonalDocument < ActiveRecord::Base
    attr_accessible :document_attachment, :person

    belongs_to :document_attachment
    belongs_to :person
    before_create :clone_file

    has_attached_file :file, {
      :storage => :filesystem,
      :path => ":rails_root/:dav_root/:person/:slug/:filename",
      :url => "/:dav_root/:person/:slug/:filename",
    }
    
    scope :derived_from, lambda { |document|
      select("droom_personal_documents.*")
        .joins("INNER JOIN droom_document_attachments on droom_personal_documents.document_attachment_id = droom_document_attachments.id")
        .where(["droom_document_attachments.document_id = ?", document.id])
    }

    scope :belonging_to, lambda { |person|
      where(["person_id = ?", person.id])
    }
    
    def document
      document_attachment.document
    end
    
    def document=(doc)
      document_attachment = Droom::DocumentAttachment.create(:document => doc)
    end
    
    def name
      document.name
    end

    def description
      document.description
    end
    
    def file_changed?
      file_fingerprint != Digest::MD5.file(file.path).to_s
    end

    def file_touched?
      File.mtime(file.path) > Time.at(file.updated_at)
    end
  
    def file_path
      
    end
    
    def url
      file.url if file
    end
    
    def slug
      document_attachment.slug
    end

    def category
      document_attachment.category
    end
    
    def file_extension
      File.extname(file_file_name).sub(/^\./, '')
    end
    
    def reclone_if_changed
      reclone_file if document.version > self.version
    end
    
  protected
  
    def clone_file
      self.version = document.version
      self.file = document.file
    end
    
    def reclone_file
      archive_file if file? && file_touched?
      clone_file
    end
    
    # If the previous file for some reason needs to be preserved - usually because it has been edited
    # in some way by its owner - we archive it by interpolating _vX into the filename, where X is
    # the current version of this personal document (which is the same as the old version of its
    # document. Calling clone_file again will update our version as well as retrieving the new file.
    # This way we can avoid storing all the files with redundant version suffixed (almost everything would
    # be _v1), keep useful older versions in a comprebensible way and discard old versions that aren't special.
    #
    def archive_file
      suffix = File.extname(file_file_name)
      stem = File.basename(file_file_name, suffix)
      dir = File.dirname(file.path)
      FileUtils.move(file.path, "#{dir}/#{stem}_v#{version}#{suffix}")
    end
  end
end
