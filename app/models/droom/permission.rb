module Droom
  class Permission < ActiveRecord::Base
    attr_accessible :name
    belongs_to :resource
    has_many :group_permissions, :dependent => :destroy
    has_many :user_permissions, :dependent => :destroy

    before_save :set_code
    
  protected
    
    def set_code
      self.code = [resource.name, self.name].join('.')
    end
  end
end