class PrivilegedGroups < ActiveRecord::Migration
  def change
    add_column :droom_groups, :privileged, :boolean, default: false
    add_index :droom_groups, :privileged
  end
end
