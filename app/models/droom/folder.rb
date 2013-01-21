module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :name, :slug, :parent

    belongs_to :created_by, :class_name => Droom.user_class
    belongs_to :holder, :polymorphic => true
    has_many :documents
    has_many :personal_folders
    has_ancestry
    
    validates :holder, :presence => true
    validates :slug, :presence => true, :uniqueness => true
    
    before_validation :get_slug

    def descent
      path.join('/')
    end
    
    def empty?
      documents.empty?
    end
    
  protected
  
    def get_slug
      self.slug = holder.slug
    end
  
  end
end
