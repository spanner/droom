module Droom
  class Permission < ActiveRecord::Base
    belongs_to :service
    has_many :group_permissions, :dependent => :destroy
    has_many :user_permissions, :dependent => :destroy
    acts_as_list :scope => :service_id
    before_save :set_slug
    
    validates :slug, :uniqueness => true
    
  protected
    
    def set_slug
      self.slug = [service.slug, self.name].join('.')
    end
  end
end