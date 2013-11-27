class DirectoryGroups < ActiveRecord::Migration
  def change
    add_column :droom_groups, :directory, :boolean
    add_column :droom_events, :confidential, :boolean
    add_index :droom_groups, :directory
    add_index :droom_events, :confidential
  end
end
