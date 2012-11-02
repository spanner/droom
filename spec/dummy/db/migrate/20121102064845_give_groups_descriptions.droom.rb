# This migration comes from droom (originally 20121009075049)
class GiveGroupsDescriptions < ActiveRecord::Migration
  def change
    add_column :droom_groups, :description, :text
  end
end
