class MergedUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :droom_users, :merged_with, :text
  end
end
