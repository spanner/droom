require 'zip/zip'
require 'open-uri'

module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :name, :parent, :parent_id

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents, :dependent => :destroy
    has_many :personal_folders, :dependent => :destroy
    acts_as_tree :order => "name ASC"

    validates :slug, :presence => true, :uniqueness => { :scope => :parent_id }

    before_validation :set_properties
    before_validation :ensure_slug
    
    default_scope includes(:documents)

    scope :all_private, where("#{table_name}.private = 1")
    scope :not_private, where("#{table_name}.private <> 1 OR #{table_name}.private IS NULL")
    scope :all_public, where("#{table_name}.public = 1 AND #{table_name}.private <> 1 OR #{table_name}.private IS NULL")
    scope :not_public, where("#{table_name}.public <> 1 OR #{table_name}.private = 1)")
    scope :by_name, order("#{table_name}.name ASC")
    scope :visible_to, lambda { |person|
      if person
        select('droom_folders.*')
          .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON droom_folders.id = dpf.folder_id')
          .where(["(droom_folders.public = 1 OR dpf.person_id = ?)", person.id])
          .group('droom_folders.id')
      else
        all_public
      end
    }
    
    def visible_to?(person)
      true
    end

    # A root folder is created automatically for each class that has_folders,
    # the first time something in that class asks for its folder.
    # scope :roots, where('droom_folders.holder_type IS NULL AND droom_folders.parent_id IS NULL')

    scope :loose, where('parent_id IS NULL')

    scope :populated, select('droom_folders.*')
      .joins('LEFT OUTER JOIN droom_documents AS dd ON droom_folders.id = dd.folder_id LEFT OUTER JOIN droom_folders AS df ON droom_folders.id = df.parent_id')
      .having('count(dd.id) > 0 OR count(df.id) > 0')
      .group('droom_folders.id')

    scope :latest, lambda {|limit|
      order("updated_at DESC, created_at DESC").limit(limit)
    }

    def path
      "#{parent.path if parent}/#{slug}"
    end

    def documents_zipped
      if self.documents.any?
        tempfile = Tempfile.new("droom-temp-#{slug}-#{Time.now}.zip")
        Zip::ZipOutputStream.open(tempfile.path) do |z|
          self.documents.each do |doc|
            z.add(doc.file_file_name, doc.original_file)
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
    
    def simple?
      children.empty? && documents.count <= 3
    end
    
    # If we start to get deep folder trees we'll have to use ancestry instead of acts_as_tree.
    def family
      self_and_children
    end
    
    def loose?
      !parent
    end
    
    def ancestor_of?(folder)
      folder && folder.ancestors.include?(self)
    end

    def copy_to_dropbox(user)
      Rails.logger.warn ">>> creating dropbox subfolder #{slug} for user #{user.name}"
      documents.each { |doc| doc.copy_to_dropbox(user) }
    end
    
    def dropboxed_for?(user)
      # user.person && dropbox_documents.for_person(person).any?
    end

    def copy_to_dav
      Rails.logger.warn ">>> copy folder #{@folder.inspect} to DAV"
    end
    
    def get_name_from_holder
      send :set_properties
      self.save if self.changed?
    end

  protected

    def set_properties
      if holder
        self.name ||= holder.name
        self.slug ||= holder.slug
      end
      # folders originally only had slugs, so this happens from time to time
      self.name ||= self.slug
      self.public = !holder && (!parent || parent.public?)
      true
    end

    def ensure_slug
      ensure_presence_and_uniqueness_of(:slug, name.parameterize)
    end

  end
end
