class UserTitles < ActiveRecord::Migration
  def change
    add_column :droom_users, :title, :string
  end
end
