module Droom
  class UserPermission < ActiveRecord::Base
    belongs_to :user
    belongs_to :permission
    belongs_to :group_permission
  end
end