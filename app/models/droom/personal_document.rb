module Droom
  class PersonalDocument < ActiveRecord::Base

    belongs_to :attachment
    belongs_to :person
    before_save :clone_file

    has_attached_file :file, {
      :storage => :file,
      :path => ":rails_root/webdav/:person/:slug/:document"
    }
    
    def file_changed?
      file.fingerprint != file_fingerprint
    end

    def file_touched?
      File.mtime(file.uploaded_file) > file.updated_at
    end
  
  protected
  
    def clone_file
      # this will be a delayed job
      self.file = document.file unless file? && file_changed?
    end
  end
end
