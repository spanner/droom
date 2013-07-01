module Droom
  class Service < ActiveRecord::Base
    attr_accessible :name, :slug
    has_many :permissions, :dependent => :destroy
    before_save :set_slug
    validates :slug, :uniqueness => true
    
  protected
  
    def set_slug
      self.slug ||= name.parameterize
    end

  end
end