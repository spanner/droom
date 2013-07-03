module Droom
  class Service < ActiveRecord::Base
    attr_accessible :name, :slug, :description
    has_many :permissions, :dependent => :destroy, :order => "position ASC"
    before_save :set_slug
    validates :slug, :uniqueness => true
    
  protected
  
    def set_slug
      Rails.logger.warn ">>> setting slug on service #{self.inspect}"
      self.slug ||= name.parameterize
    end

  end
end