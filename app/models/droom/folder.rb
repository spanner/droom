require 'zip/zip'
require 'open-uri'

module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :slug, :parent, :parent_id

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents, :dependent => :destroy
    has_many :personal_folders, :dependent => :destroy
    acts_as_tree

    validates :slug, :presence => true, :uniqueness => { :scope => :parent_id }

    before_validation :set_slug
    before_save :set_properties
    
    default_scope includes(:children, :documents)

    scope :all_private, where("#{table_name}.private = 1")
    scope :not_private, where("#{table_name}.private <> 1 OR #{table_name}.private IS NULL")
    scope :all_public, where("#{table_name}.public = 1 AND #{table_name}.private <> 1 OR #{table_name}.private IS NULL")
    scope :not_public, where("#{table_name}.public <> 1 OR #{table_name}.private = 1)")

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

    # A root folders is created automatically for each class that has_folder, 
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

    def name
      if holder
        holder.name
      else
        slug
      end
    end
        
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

    def copy_to_dav
      Rails.logger.warn ">>> copy folder #{@folder.inspect} to DAV"
    end

  protected

    def set_slug
      self.slug ||= holder.slug if holder
      self.slug = self.slug.parameterize
      true
    end

    def set_properties
      self.public = !holder && (!parent || parent.public?)
      true
    end

  end
end
