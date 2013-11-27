# This migration comes from droom (originally 20130326135738)
class UserTitles < ActiveRecord::Migration
  def change
    add_column :droom_users, :title, :string
  end
end
