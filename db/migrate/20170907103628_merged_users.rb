class MergedUsers < ActiveRecord::Migration
  def change
    add_column :droom_users, :merged_with, :text
  end
end
