class Preferences < ActiveRecord::Migration
  def change
    create_table :droom_preferences do |t|
      t.integer :created_by_id
      t.string :key
      t.string :value
      t.timestamps
    end
  end
end
