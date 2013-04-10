# This migration comes from droom (originally 20130130120124)
class FolderAncestryToParents < ActiveRecord::Migration
  def change
    change_column :droom_folders, :ancestry, :integer
    rename_column :droom_folders, :ancestry, :parent_id
    remove_index :droom_folders, :ancestry
  end
end
