class CreateGroupInvitations < ActiveRecord::Migration
  def change
    create_table :droom_group_invitations do |t|
      t.integer :group_id
      t.integer :event_id
      t.integer :created_by_id
    end
    add_column :droom_invitations, :group_invitation_id, :integer
  end
end
