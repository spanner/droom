module Droom
  class GroupPermission < Droom::DroomRecord
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

    def delete_permissions(read_only = false)
      klass = Droom::Permission
      if permission = klass.find(self.permission_id)
        read_permission = klass.find_by(name: "#{permission.name}.read")
        self.permission_id = read_permission.id if read_only == 'true'

        self.class.where(group_id: self.group_id, permission_id: read_permission.try(:id)).destroy_all
        self.class.where(group_id: self.group_id, permission_id: permission.id).destroy_all
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
