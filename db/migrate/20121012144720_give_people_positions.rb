class GivePeoplePositions < ActiveRecord::Migration
  def change
    add_column :droom_people, :position, :integer, :default => 1
  end
end
