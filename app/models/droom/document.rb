module Droom
  class Document < Droom::DroomRecord
    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :folder
    belongs_to :scrap, :dependent => :destroy

    has_attached_file :file,
                      fog_directory: -> a { a.instance.file_bucket }

    acts_as_list scope: :folder_id

    before_create :inherit_confidentiality

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

    scope :unindexed, -> { where(indexed_at: nil) }

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
    searchkick callbacks: false, default_fields: [:name, :content], highlight: [:name, :content]
    after_save :enqueue_for_indexing

    def search_data
      {
        name: name || "",
        filename: file_file_name || "",
        content_type: get_content_type,
        content: @file_content || "",
        event_type: get_event_type || "",
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

    # called from containing folder when confidentiality changes
    # calls save properly to allow for various indexing regimes.
    def set_confidentiality!(confidentiality)
      assign_attributes private: confidentiality
      save!
    end

    # called before_create
    def inherit_confidentiality
      write_attribute :private, folder && folder.confidential?
      true
    end

    def enqueue_for_indexing!
      Rails.logger.debug "⚠️ enqueue_for_indexing Droom::Document #{id}"
      Droom::IndexDocumentJob.perform_later(id, Time.now.to_i)
    end

    def enqueue_for_indexing
      if saved_change_to_name? || saved_change_to_file_file_name? || saved_change_to_file_fingerprint?
        enqueue_for_indexing!
      end
    end

    def update_index!
      with_local_file do |path|
        @file_content = Yomu.new(path).text
        self.reindex
        self.secondary_reindex
      end
      self.update_column(:indexed_at, Time.now)
      true
    end

    def secondary_reindex
      # noop here
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
