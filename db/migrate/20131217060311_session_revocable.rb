class SessionRevocable < ActiveRecord::Migration
  def change
    add_column :droom_users, :session_id, :string
  end
end
