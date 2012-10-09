class GiveGroupsDescriptions < ActiveRecord::Migration
  def change
    add_column :droom_groups, :description, :text
  end
end
