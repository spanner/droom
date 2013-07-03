module Droom
  class Service < ActiveRecord::Base
    attr_accessible :name, :slug, :description
    has_many :permissions, :dependent => :destroy, :order => "position ASC"
    before_save :set_slug
    after_create :create_basic_permissions
    validates :slug, :uniqueness => true
    
    def self.for_selection
      self.order("name asc").map{|f| [f.name, f.id] }
    end
    
  protected
  
    def set_slug
      Rails.logger.warn ">>> setting slug on service #{self.inspect}"
      self.slug ||= name.parameterize
    end
    
    def create_basic_permissions
      permissions.create(:name => 'login')
      permissions.create(:name => 'admin')
    end
  end
end