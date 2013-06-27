module Droom
  class Permission < ActiveRecord::Base
    attr_accessible :name
    belongs_to :resource
    has_many :group_permissions, :dependent => :destroy
    has_many :groups, :through => :group_permissions
  end
end