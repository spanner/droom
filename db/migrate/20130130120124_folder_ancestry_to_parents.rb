class FolderAncestryToParents < ActiveRecord::Migration
  def change
    change_column :droom_folders, :ancestry, :integer
    rename_column :droom_folders, :ancestry, :parent_id
  end
end
