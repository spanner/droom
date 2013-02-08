require 'zip/zip'
require 'dropbox_sdk'

module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :slug, :parent

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents
    has_many :personal_folders
    has_many :folders
    acts_as_tree

    validates :slug, :presence => true, :uniqueness => { :scope => :parent_id }

    before_validation :set_slug
    before_save :set_properties

    scope :visible_to, lambda { |person|
      # if person
      #   select('droom_folders.*')
      #     .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON droom_folders.id = dpf.folder_id')
      #     .where(["(droom_folders.public = 1 OR dpf.person_id = ?)", person.id])
      #     .group('droom_folders.id')
      # else
      #   all_public
      # end
      not_private
    }

    scope :roots, select('parent_id IS NULL')

    scope :populated, select('droom_folders.*')
      .joins('LEFT OUTER JOIN droom_documents AS dd ON droom_folders.id = dd.folder_id')
      .having('count(dd.id) > 0')
      .group('droom_folders.id')

    scope :latest, lambda {|limit|
      order("updated_at DESC, created_at DESC").limit(limit)
    }

    # These are going to be Droom.* configurable
    scope :all_private, where("secret = 1")
    scope :not_private, where("secret <> 1")
    scope :all_public, where("public = 1 AND secret <> 1")
    scope :not_public, where("public <> 1 OR secret = 1)")

    def name
      holder.name if holder
    end
        
    def path
      if parent
        parent.path + "/#{slug}"
      else
        "/#{slug}"
      end
    end

    def empty?
      documents.empty?
    end
    
    def documents_zipped
      if self.documents.any?
        tempfile = Tempfile.new("droom-temp-#{slug}-#{Time.now}.zip")
        Zip::ZipOutputStream.open(tempfile.path) do |z|
          self.documents.each do |doc|
            z.add(doc.file_file_name, open(doc.file.url))
          end
        end
        tempfile
      end
    end

    def populated?
      children.any? || documents.any?
    end

    def empty?
      !populated?
    end

    def copy_to_dropbox(user)
      Rails.logger.warn ">>> creating dropbox folder"
      if dt = user.dropbox_token
        dbsession = DropboxSession.new(Droom.dropbox_app_key, Droom.dropbox_app_secret)
        dbsession.set_access_token(dt.access_token, dt.access_token_secret)
        dbclient = DropboxClient.new(dbsession)
        documents.each do |doc|
          Rails.logger.warn ">>> putting file #{doc.file} to dropbox with path #{self.path}"
          dbclient.put_file(path, doc.original_file)
        end
      end
    end

    def copy_to_dav
      Rails.logger.warn ">>> copy folder #{@folder.inspect} to DAV"
    end

  protected

    def set_slug
      self.slug = holder.slug if holder
      true
    end

    def set_properties
      self.public = !holder && (!parent || parent.public?)
      true
    end

  end
end
