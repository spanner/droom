require 'open-uri'
require 'dropbox_sdk'
require 'yomu'

module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file, :description, :folder, :folder_id

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :folder
    has_many :dropbox_documents
    has_attached_file :file

    after_save :update_dropbox_documents
    after_destroy :mark_dropbox_documents_deleted

    validates :file, :presence => true

    scope :all_private, where("private = 1")
    scope :not_private, where("private <> 1 OR private IS NULL")
    scope :all_public, where("public = 1 AND private <> 1 OR private IS NULL")
    scope :not_public, where("public <> 1 OR private = 1)")

    scope :visible_to, lambda { |user|
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

    scope :matching, lambda { |fragment|
      fragment = "%#{fragment}%"
      where('droom_documents.name LIKE :f OR droom_documents.file_file_name LIKE :f', :f => fragment)
    }
    
    scope :in_folders, lambda{ |folders|
      placeholders = folders.map { "?" }.join(',')
      where(["folder_id IN(#{placeholders})", *folders.map(&:id)])
    }

    scope :by_date, order("droom_documents.updated_at DESC, droom_documents.created_at DESC")

    scope :latest, lambda {|limit|
      order("droom_documents.updated_at DESC, droom_documents.created_at DESC").limit(limit)
    }

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

  end
end
