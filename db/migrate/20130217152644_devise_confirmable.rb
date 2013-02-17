class DeviseConfirmable < ActiveRecord::Migration
  def change
    add_column :droom_users, :confirmation_token, :string
    add_column :droom_users, :confirmed_at, :datetime
    add_column :droom_users, :confirmation_sent_at, :datetime
    add_column :droom_users, :unconfirmed_email, :string
    add_index :droom_users, :confirmation_token, :unique => true
    
    remove_column :droom_users, :invited_at
    remove_column :droom_users, :invited_by_id
    remove_column :droom_users, :activated_at
  end
end
