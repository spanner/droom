class FoldersNicely < ActiveRecord::Migration
  def change
    add_column :droom_folders, :name, :string
    Droom::Folder.all.map(&:get_name_from_holder)
  end
end
