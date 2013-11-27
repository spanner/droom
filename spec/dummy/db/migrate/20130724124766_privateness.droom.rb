# This migration comes from droom (originally 20130228083509)
class Privateness < ActiveRecord::Migration
  def change
    add_column :droom_folders, :private, :boolean
    rename_column :droom_documents, :secret, :private
    rename_column :droom_people, :shy, :private
    add_column :droom_groups, :private, :boolean
    add_column :droom_groups, :public, :boolean
  end
end
