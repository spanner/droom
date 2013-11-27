module Droom
  class PersonalFolder < ActiveRecord::Base
    belongs_to :user
    belongs_to :folder
    
    scope :of_folder, -> folder {
      where(["folder_id = ?", folder.id])
    }

    scope :for_user, -> user {
      where(["user_id = ?", user.id])
    }
    
    def copy_to_dropbox
      
    end
    
  end
end
