# This migration comes from droom (originally 20130207091903)
class PreferenceUuids < ActiveRecord::Migration
  def change
    add_column :droom_preferences, :uuid, :string
  end
end
