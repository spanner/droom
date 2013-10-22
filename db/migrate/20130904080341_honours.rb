class Honours < ActiveRecord::Migration
  def change
    rename_column :droom_users, :honours, :string
  end
end
