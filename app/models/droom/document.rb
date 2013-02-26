require 'open-uri'
require 'dropbox_sdk'

module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file, :description, :folder, :folder_id

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :folder

    has_attached_file :file
    after_post_process :extract_text

    before_save :set_version
    after_destroy :destroy_folder_if_empty
    
    validates :file, :presence => true

    searchable do
      text :name, :boost => 10, :stored => true
      text :description, :stored => true
      text :extracted_text, :stored => true
    end

    scope :all_private, where("secret = 1")
    scope :not_private, where("secret <> 1")
    scope :all_public, where("public = 1 AND secret <> 1")
    scope :not_public, where("public <> 1 OR secret = 1)")

    scope :visible_to, lambda { |person|
      if person
        select('droom_documents.*')
          .joins('LEFT OUTER JOIN droom_folders AS df ON droom_documents.folder_id = df.id')
          .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON df.id = dpf.folder_id')
          .where(["(droom_documents.public = 1 OR dpf.person_id = ?)", person.id])
          .group('droom_documents.id')
      else
        all_public
      end
    }

    scope :matching, lambda { |fragment|
      fragment = "%#{fragment}%"
      where('droom_documents.name LIKE :f OR droom_documents.file_file_name LIKE :f', :f => fragment)
    }

    scope :by_date, order("droom_documents.updated_at DESC, droom_documents.created_at DESC")

    def self.highlight_fields
      [:name, :description, :extracted_text]
    end

    def attach_to(holder)
      self.folder = holder.folder
    end

    def detach_from(holder)
      self.folder = nil if self.folder == holder.folder
    end

    def file_ok?
      file.exists?
    end
    
    def original_file
      open(self.file.url)
    end

    def full_path
      "#{folder.path if folder}/#{file_file_name}"
    end
    
    def changed_since_creation?
      file_updated_at > created_at
    end

    def file_extension
      if file_file_name
        File.extname(file_file_name).sub(/^\./, '')
      else
        ""
      end
    end

    def as_suggestion
      {
        :type => 'document',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def as_search_result
      {
        :type => 'document',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def index
      Sunspot.index!(self)
    end
    
    def copy_to_dropbox(user)
      if dbclient = user.dropbox_client
        dbclient.put_file(full_path, original_file)
      end
    end

  protected

    def set_version
      if file.dirty?
        self.version = (version || 0) + 1
      end
    end

    def destroy_folder_if_empty
      self.folder.destroy if self.folder && self.folder.empty?
    end

    def halt_unless_pdf
      false unless file_extension == 'pdf'
    end

    def extract_text
      require 'yomu'
      data = File.read "#{file.queued_for_write[:original].path}"
      plain_text = Yomu.read :text, data
      metadata = Yomu.read :metadata, data
      # Rails.logger.warn ">>> metadata => #{metadata}"
      self.extracted_text = plain_text #text column to hold the extracted text for searching
    end
  end
end
