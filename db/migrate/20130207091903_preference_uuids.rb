class PreferenceUuids < ActiveRecord::Migration
  def change
    add_column :droom_preferences, :uuid, :string
  end
end
