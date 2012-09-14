module Droom
  class PersonalDocument < ActiveRecord::Base
    attr_accessible :document_attachment, :person

    belongs_to :document_attachment
    belongs_to :person
    before_create :clone_file

    has_attached_file :file, {
      :storage => :filesystem,
      :path => ":rails_root/webdav/:person/:slug/:filename"
    }
    
    def document
      document_attachment.document
    end
    
    def document=(doc)
      document_attachment = Droom::DocumentAttachment.create(:document => doc)
    end
    
    def file_changed?
      file.fingerprint != file_fingerprint
    end

    def file_touched?
      File.mtime(file.uploaded_file) > file.updated_at
    end
  
    def file_path
      
    end
    
    def slug
      document_attachment.slug
    end
    
  protected
  
    def clone_file
      # this will end up as a delayed job
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
