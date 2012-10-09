class MoreNames < ActiveRecord::Migration
  def change
    add_column :droom_people, :forename, :string
  end
end
