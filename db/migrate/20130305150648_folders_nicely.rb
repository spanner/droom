class FoldersNicely < ActiveRecord::Migration
  def change
    add_column :droom_folders, :name, :string
  end
end
