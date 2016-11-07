require 'open-uri'
require 'dropbox_sdk'

module Droom
  class Document < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :folder
    belongs_to :scrap, :dependent => :destroy
    has_many :dropbox_documents

    has_attached_file :file,
                      fog_directory: -> a { a.instance.file_bucket }

    after_save :update_dropbox_documents
    after_destroy :mark_dropbox_documents_deleted

    validates :file, :presence => true
    do_not_validate_attachment_file_type :file

    scope :all_private, -> { where("private = 1") }
    scope :not_private, -> { where("private <> 1 OR private IS NULL") }
    scope :all_public, -> { where("public = 1 AND private <> 1 OR private IS NULL") }
    scope :not_public, -> { where("public <> 1 OR private = 1)") }

    scope :visible_to, -> user {
      if user
        select('droom_documents.*')
          .joins('LEFT OUTER JOIN droom_folders AS df ON droom_documents.folder_id = df.id')
          .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON df.id = dpf.folder_id')
          .where(["(droom_documents.public = 1 OR dpf.user_id = ?)", user.id])
          .group('droom_documents.id')
      else
        all_public
      end
    }

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_documents.name LIKE :f OR droom_documents.file_file_name LIKE :f', :f => fragment)
    }
    
    scope :in_folders, -> folders{
      placeholders = folders.map { "?" }.join(',')
      where(["folder_id IN(#{placeholders})", *folders.map(&:id)])
    }

    scope :by_date, -> { order("droom_documents.updated_at DESC, droom_documents.created_at DESC") }

    scope :latest, -> limit { order("droom_documents.updated_at DESC, droom_documents.created_at DESC").limit(limit) }

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

    def copy_to_dropbox(user)
      dropbox_documents.create(:user => user)
    end

    def mark_dropbox_documents_deleted
      dropbox_documents.each do |dd|
        dd.mark_deleted(true)
      end
    end

    def create_dropbox_documents
      # after create, in a delayed job
      # for each user who is syncing our folder, create a dropbox document
      # that is: everyone who has the sync everything preference or who is associated with the holder of this folder
    end

    def update_dropbox_documents
      dropbox_documents.each do |dd|
        dd.update
      end
    end

    ## Filing
    #
    # Some installations like to use different buckets for various purposes.
    # Override `file_bucket` if you want to choose a bucket at runtime.
    #
    def file_bucket
      Settings.aws.asset_bucket
    end

    ## Search
    #
    searchkick callbacks: false, highlight: [:title, :content]
    attr_accessor :updating_index
    after_save :enqueue_for_indexing, unless: :updating_index?

    def search_data
      {
        name: name || "",
        filename: file_file_name || "",
        content_type: get_content_type,
        content: @file_content || "",
        event_type: get_event_type || "'",
        year: get_year || "",
        confidential: confidential?
      }
    end

    def get_content_type
      content_type = Friendly::MIME.find(file_content_type) if file_content_type?
      content_type || "Unknown"
    end

    def get_event_type
      if folder && folder.holder && folder.holder.is_a?(Droom::Event) && folder.holder.event_type
        folder.holder.event_type.slug
      end
    end

    def get_year
      created_at.year if created_at?
    end

    def confidential?
      confidential = private?
      confidential ||= folder.confidential? if folder
      confidential
    end

    def enqueue_for_indexing
      if name_changed? || file_file_name_changed? || file_fingerprint_changed?
        Droom::IndexDocumentJob.perform_later(id, Time.now.to_i)
      end
    end

    def update_index!
      unless self.updating_index
        self.updating_index = true
        with_local_file do |path|
          @file_content = Yomu.new(path).text
          self.reindex
        end
        self.update_column(:indexed_at, Time.now)
        self.updating_index = false
      end
    end

    def updating_index?
      !!updating_index
    end

    # Pass block to perform operations with a local file, which will be
    # pulled down from S3 if no other version is available.
    #
    def with_local_file
      if file?
        if File.file?(file.path)
          yield file.path
        elsif file.queued_for_write[:original]
          yield file.queued_for_write[:original].path
        else
          tempfile_path = copy_to_local_tempfile
          yield tempfile_path
          File.delete(tempfile_path) if File.file?(tempfile_path)
        end
      end
    end

    def copy_to_local_tempfile
      if file?
        begin
          folder = self.class.to_s.downcase.pluralize
          tempfile_path = Rails.root.join("tmp/#{folder}/#{id}/#{file_file_name}")
          FileUtils.mkdir_p(Rails.root.join("tmp/#{folder}/#{id}"))
          file.copy_to_local_file(:original, tempfile_path)
        rescue => e
          # raise Cdr::FileReadError, "Original file could not be read: #{e.message}"
          Rails.logger.warn "File read failure: #{e.message}"
        end
        tempfile_path
      end
    end


  end
end
