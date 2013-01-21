module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    after_create :link_folder
    after_destroy :unlink_folder

    scope :of_group, lambda { |group|
      where(["group_id = ?", group.id])
    }

    def link_folder
      person.add_personal_folders(group.folder)
    end
  
    def unlink_folder
      person.remove_personal_folders(group.folder)
    end

  end
end