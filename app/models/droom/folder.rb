require 'open-uri'
require 'acts_as_tree'

module Droom
  class Folder < ApplicationRecord
    include ActsAsTree
    include Droom::Concerns::Slugged

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents, -> {order(position: :asc, file_file_name: :asc)}, :dependent => :destroy
    acts_as_tree :order => "droom_folders.name ASC"

    validates :slug, :presence => true, :uniqueness => { :scope => :parent_id }

    before_validation :set_properties
    before_validation :slug_from_name
    
    default_scope -> { includes(:documents) }

    scope :all_private, -> { where("#{table_name}.private = 1") }
    scope :not_private, -> { where("#{table_name}.private <> 1 OR #{table_name}.private IS NULL") }
    scope :all_public, -> { where("#{table_name}.public = 1 AND #{table_name}.private <> 1 OR #{table_name}.private IS NULL") }
    scope :not_public, -> { where("#{table_name}.public <> 1 OR #{table_name}.private = 1)") }
    scope :by_name, -> { order("#{table_name}.name ASC") }
    scope :other_than, -> folders {where.not(id: folders.map(&:id))}

    def automatic?
      holder || !parent && (name == "Events" || name == "Groups")
    end
    
    def visible_to?(user)
      return true if self.public?
      return false unless user
      return true if user.admin?
      return true if user.has_folder?(self)
      return false if self.private?
      return true
    end

    # A root folder is created automatically for each class that has_folders,
    # the first time something in that class asks for its folder.
    # scope :roots, where('droom_folders.holder_type IS NULL AND droom_folders.parent_id IS NULL')
    #
    scope :loose, -> { where('parent_id IS NULL') }
    scope :latest, -> limit { order("updated_at DESC, created_at DESC").limit(limit) }
    scope :populated, -> {
      select('droom_folders.*')
        .joins('LEFT OUTER JOIN droom_documents AS dd ON droom_folders.id = dd.folder_id LEFT OUTER JOIN droom_folders AS df ON droom_folders.id = df.parent_id')
        .having('count(dd.id) > 0 OR count(df.id) > 0')
        .group('droom_folders.id')
    }

    def path
      "#{parent.path if parent}/#{slug}"
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

    def get_name_from_holder
      send :set_properties
      self.save if self.changed?
    end

    def get_event_type
      if holder && holder.is_a?(Droom::Event) && holder.event_type
        holder.event_type
      end
    end

    def confidential?
      confidential = private?
      if et = get_event_type
        confidential ||= et.confidential?
      end
      confidential
    end

    # called from event type or parent folder when confidentiality changes
    def set_confidentiality!(confidentiality)
      if holder and holder.confidential?
        # folder attached to a confidential object will always be confidential,
        #  even if its parent has just been made available.
        confidentiality = true
      end
      assign_attributes private: confidentiality
      save!
    end

    # called before_create
    def inherit_confidentiality
      if holder
        write_attribute :private, holder.confidential?
      elsif parent
        write_attribute :private, parent.confidential?
      end
      true
    end

    # called after_save, including after set_confidentiality!
    def distribute_confidentiality
      documents.each {|document| document.set_confidentiality!(confidential?) }
      children.each {|folder| folder.set_confidentiality!(confidential?) }
    end

  protected

    def set_properties
      if holder
        if holder.respond_to?(:folder_name)
          self.name ||= holder.folder_name
        else
          self.name ||= holder.name
        end
        self.slug ||= holder.slug
      end
      # folders originally only had slugs, so this happens from time to time
      self.name ||= self.slug
      self.public = !holder && (!parent || parent.public?)
      true
    end

  end
end
