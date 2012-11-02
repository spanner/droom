# This migration comes from droom (originally 20121009105244)
class MoreNames < ActiveRecord::Migration
  def change
    add_column :droom_people, :forename, :string
  end
end
