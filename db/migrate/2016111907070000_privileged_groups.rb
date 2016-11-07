class PrivilegedGroups < ActiveRecord::Migration
  def change
    add_column :droom_groups, :privileged, :boolean, default: false
  end
end
