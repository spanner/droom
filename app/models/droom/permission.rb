module Droom
  class Permission < ActiveRecord::Base
    attr_accessible :name
    belongs_to :service
    has_many :group_permissions, :dependent => :destroy
    has_many :user_permissions, :dependent => :destroy

    before_save :set_slug
    
    validates :slug, :uniqueness => true
    
  protected
    
    def set_slug
      self.slug = [service.slug, self.name].join('.')
    end
  end
end