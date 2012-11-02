# This migration comes from droom (originally 20121102094738)
class ShyPeople < ActiveRecord::Migration
  def change
    rename_column :droom_people, :private, :shy
  end
end
