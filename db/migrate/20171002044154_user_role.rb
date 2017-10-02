class UserRole < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_users, :role, :string
  end
end
