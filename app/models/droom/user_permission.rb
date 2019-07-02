module Droom
  class UserPermission < Droom::DroomRecord
    belongs_to :user
    belongs_to :permission
    belongs_to :group_permission
    scope :for_user, -> user { where(["user_id = ?", user.id]) }
  end
end