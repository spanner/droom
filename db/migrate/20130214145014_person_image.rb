class PersonImage < ActiveRecord::Migration
  def up
    add_upload :droom_people, :image
  end

  def down
    remove_upload :droom_people, :image
  end
end
