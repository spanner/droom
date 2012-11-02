class PeopleVisibility < ActiveRecord::Migration
  def change
    add_column :droom_people, :public, :boolean
    add_column :droom_people, :private, :boolean
    add_index :droom_people, :public
  end
end
