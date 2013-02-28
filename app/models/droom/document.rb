module Droom
  require 'iconv'
  class Document < ActiveRecord::Base
    attr_accessible :name, :file, :description, :attachment_category_id, :event_id

    # attachment_category and event_id are used on document creation to create an associated attachment
    # this is a temporary shortcut 
    attr_accessor :old_version, :attachment_category_id, :event_id

    belongs_to :created_by, :class_name => 'User'

    has_many :document_attachments, :dependent => :destroy
    has_many :document_links, :through => :document_attachments
    has_many :people, :through => :document_links

    has_attached_file :file, :styles => { :text => { :fake => 'variable' } }, :processors => [:text], :whiny => true, :log => true

    after_post_process :extract_text

    before_save :set_version
    validates :file, :presence => true

    scope :all_private, where("secret = 1")
    scope :not_private, where("secret <> 1")
    scope :all_public, where("public = 1 AND secret <> 1")
    scope :not_public, where("public <> 1 OR secret = 1)")

    scope :visible_to, lambda { |person|
      if person
        select('droom_documents.*')
          .joins('LEFT OUTER JOIN droom_document_attachments AS dda ON droom_documents.id = dda.document_id')
          .joins('LEFT OUTER JOIN droom_document_links AS ddl ON dda.id = ddl.document_attachment_id')
          .where(["(droom_documents.public = 1 OR ddl.person_id = ?)", person.id])
          .group('droom_documents.id')
      else
        all_public
      end
    }

    scope :name_matching, lambda { |fragment|
      fragment = "%#{fragment}%"
      where('droom_documents.name like ?', fragment)
    }

    scope :attached_to_these_groups, lambda { |groups|
      placeholders = groups.map{'?'}.join(',')
      select('droom_documents.*')
        .joins('INNER JOIN droom_document_attachments ON droom_documents.id = droom_document_attachments.document_id AND droom_document_attachments.attachee_type = "Droom::Group"')
        .where(["droom_document_attachments.attachee_id IN(#{placeholders})", *groups.map(&:id)])
    }

    scope :with_latest_event, 
      select('droom_documents.*, droom_categories.name AS category_name, droom_events.id AS latest_event_id, droom_events.name AS latest_event_name')
        .joins('LEFT OUTER JOIN droom_document_attachments AS da ON droom_documents.id = da.document_id 
                LEFT OUTER JOIN droom_categories ON da.category_id = droom_categories.id
                LEFT OUTER JOIN droom_events ON da.attachee_id = droom_events.id AND da.attachee_type = "Droom::Event"')
        .group('droom_documents.id')

    # so that we can apply the joined finders above to an existing object
    #
    scope :this_document, lambda { |doc|
      where(["droom_documents.id = ?", doc.id])
    }

    scope :by_date, order("droom_documents.updated_at DESC, droom_documents.created_at DESC")

    def file_ok?
      file.exists?
    end

    def changed_since_creation?
      file_updated_at > created_at
    end

    def attachment_category_id=(id)
      attach_to(Droom::Event.find(event_id), {:category_id => id})
    end

    def attach_to(attachee, attributes={})
      save!
      document_attachments.create(attributes.merge(:attachee => attachee))
    end

    def detach_from(attachee)
      document_attachments.attached_to(attachee).destroy_all
    end

    def file_extension
      if file_file_name
        File.extname(file_file_name).sub(/^\./, '')
      else
        ""
      end
    end

    def with_event
      self.class.this_document(self).with_latest_event.first
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

    def extract_text
      pdf = File.open("#{file.queued_for_write[:text].path}","r")
      
      plain_text = ""
      while (line = pdf.gets)
        plain_text << Iconv.conv('ASCII//IGNORE', 'UTF-8', line)
      end
      self.extracted_text = plain_text #text column to hold the extracted text for searching
     end

  protected

    def index
      Sunspot.index!(self)
    end

    def set_version
      if file.dirty?
        self.version = (version || 0) + 1
      end
    end

  end
end
