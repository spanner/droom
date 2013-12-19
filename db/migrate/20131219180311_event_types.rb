class EventTypes < ActiveRecord::Migration
  def change

    create_table :droom_event_types do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.timestamps
    end
    
    add_column :droom_events, :event_type_id, :integer
    add_index :droom_events, :event_type_id

  end
end
