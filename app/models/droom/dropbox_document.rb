module Droom
  class DropboxDocument < ActiveRecord::Base
    belongs_to :user
    belongs_to :document

    validates_uniqueness_of :user_id, :scope => :document_id

    after_save  :get_file
    after_destroy :remove_dropbox_document

    def get_file
      bucket = Droom.aws_bucket
      file = bucket.files.get(document.file.path)
      dropbox_client.put_file(document.full_path, file)
    end

    def update
      get_file
    end

    def dropbox_client
      user.dropbox_client
    end

    def deleted=(boolean)
      deleted = boolean
    end

    def remove_dropbox_document
      dropbox_client.file_delete(document.full_path)
    end

    def changed?
      modified?# || dropbox_client.get_file_and_metadata(document.full_path)#dropbox file has revisions
    end

  end
end
