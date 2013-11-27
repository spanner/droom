# This migration comes from droom (originally 20130701123152)
class RemoveOldAccessControl < ActiveRecord::Migration
  def change
    remove_column :droom_groups, :private
    remove_column :droom_groups, :public
    remove_column :droom_groups, :privileged

    remove_column :droom_events, :private
    remove_column :droom_events, :public

    remove_column :droom_users, :private
    remove_column :droom_users, :public

    remove_column :droom_documents, :private
    remove_column :droom_documents, :public
  end
end
