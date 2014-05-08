class UserInstitution < ActiveRecord::Migration
  def change
    add_column :droom_users, :institution_code, :string
    add_column :droom_users, :employer, :string
    add_index :droom_users, :institution_code
  end
end
