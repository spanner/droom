module Droom
  class Document < Droom::DroomRecord
    include Droom::Concerns::Suggested

    belongs_to :created_by, optional: true, class_name: "Droom::User"
    belongs_to :folder
    belongs_to :scrap, dependent: :destroy, optional: true

    has_one_attached :file

    acts_as_list scope: :folder_id

    before_create :inherit_confidentiality
    before_save :mirror_file_columns

    # Legacy rows carry only the paperclip columns until the S3 migration
    # task attaches their blobs, so presence is satisfied by either.
    validate do
      errors.add(:file, :blank) unless file.attached? || file_file_name.present?
    end

    scope :all_private, -> { where("private = 1") }
    scope :not_private, -> { where("private <> 1 OR private IS NULL") }
    scope :all_public, -> { where("public = 1 AND private <> 1 OR private IS NULL") }
    scope :not_public, -> { where("public <> 1 OR private = 1)") }

    scope :visible_to, -> user {
      if user
        select('droom_documents.*')
          .joins('LEFT OUTER JOIN droom_folders AS df ON droom_documents.folder_id = df.id')
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

    def file?
      file.attached? || file_file_name.present?
    end

    def file_ok?
      file.attached?
    end

    # The search index, `matching` scope, folder ordering and several views
    # read the old paperclip columns, so keep them populated on new uploads.
    def mirror_file_columns
      if (change = attachment_changes["file"]) && change.respond_to?(:blob)
        self.file_file_name = change.blob.filename.to_s
        self.file_content_type = change.blob.content_type
        self.file_file_size = change.blob.byte_size
        self.file_updated_at = Time.current
      end
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

    ## Search
    #
    searchkick callbacks: false, default_fields: [:name, :content], highlight: [:name, :content]
    after_save :enqueue_for_indexing

    def search_data
      {
        type: "droom/document",
        id: id,
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
      # content_type = Friendly::MIME.find(file_content_type) if file_content_type?
      # content_type || "Unknown"
      "Unknown"
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

    # Pass block to perform operations with a local file, pulled down from
    # storage. Legacy rows whose blob has not been migrated yet are skipped.
    def with_local_file(&block)
      if file.attached?
        file.blob.open { |tempfile| yield tempfile.path }
      end
    end

  end
end
