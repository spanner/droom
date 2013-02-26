class CreateDroomCalendars < ActiveRecord::Migration
  def change
    create_table :droom_calendars do |t|
      t.integer :id
      t.string  :name
      t.string  :slug
      t.boolean :events_private, :default => false
      t.boolean :documents_private, :default => false
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_calendars, :slug
    
    add_column :droom_events, :calendar_id, :integer
    add_index :droom_events, :calendar_id
    
    add_column :droom_scraps, :event_id, :integer
    add_index :droom_scraps, :event_id
  end
end
