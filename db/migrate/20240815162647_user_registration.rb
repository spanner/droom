class UserRegistration < ActiveRecord::Migration[7.1]
  def change
    add_column :droom_users, :requires_approval, :boolean, default: false
    add_column :droom_users, :approved_at, :datetime
    add_column :droom_users, :disapproved_at, :datetime  
  end
end
