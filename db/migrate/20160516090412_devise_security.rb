class DeviseSecurity < ActiveRecord::Migration
  def change
    add_column :droom_users, :unique_session_id, :string, :limit => 20
    add_column :droom_users, :failed_attempts, :integer, default: 0
    add_column :droom_users, :locked_at, :datetime
    add_column :droom_users, :unlock_token, :string
  end
end
