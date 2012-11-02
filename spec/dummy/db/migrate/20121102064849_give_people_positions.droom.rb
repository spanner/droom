# This migration comes from droom (originally 20121012144720)
class GivePeoplePositions < ActiveRecord::Migration
  def change
    add_column :droom_people, :position, :integer, :default => 1
  end
end
