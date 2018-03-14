module Droom
  class PersonalFolder < ApplicationRecord
    belongs_to :user
    belongs_to :folder
    
    scope :of_folder, -> folder {
      where(["folder_id = ?", folder.id])
    }

    scope :for_user, -> user {
      where(["user_id = ?", user.id])
    }

  end
end
