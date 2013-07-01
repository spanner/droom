module Droom
  class GroupPermission < ActiveRecord::Base
    attr_accessible :permission_id, :group_id
    
    belongs_to :group
    belongs_to :permission
    has_many :user_permissions, :dependent => :destroy
    after_save :create_user_permissions
    
    # This is set up such that a personal permission created by group membership can be deleted
    # while still leaving in place a personal permission that was granted separately.
    #
    def create_user_permissions
      group.users.each do |user|
        create_permission_for(user)
      end
    end

    def create_permission_for(user)
      user_permissions.where(:user_id => user.id, :permission_id => permission.id).first_or_create
    end
    
    def self.by_group_id
      all.each_with_object({}) do |gp, hash|
        hash[gp.group_id] ||= {}
        hash[gp.group_id][gp.permission.id] = gp
      end
    end
    
  end
end