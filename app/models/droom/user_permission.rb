module Droom
  class UserPermission < ActiveRecord::Base
    belongs_to :user
    belongs_to :permission
    belongs_to :group_permission
    
    scope :for_user, lambda { |user|
      where(["user_id = ?", user.id])
    }
  end
end