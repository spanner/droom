module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :name, :slug, :parent

    belongs_to :created_by, :class_name => 'User'
    belongs_to :holder, :polymorphic => true
    has_many :documents
    has_many :personal_folders
    
    acts_as_tree
    
    validates :holder, :presence => true
    validates :slug, :presence => true, :uniqueness => true
    
    before_validation :get_slug

    def path
      descent.join('/')
    end
    
    def descent
      if parent
        parent.descent.push(slug) 
      else
        [slug]
      end
    end
    
  protected
  
    def get_slug
      self.slug = holder.slug
    end
  
  end
end
