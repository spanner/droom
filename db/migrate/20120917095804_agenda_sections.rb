class AgendaSections < ActiveRecord::Migration
  def change
    create_table :droom_agenda_sections do |t|
      t.string :name
      t.text :description
      t.integer :event_id
      t.integer :created_by_id
      t.timestamps
    end
    
    add_column :droom_document_attachments, :agenda_section_id, :integer
  end
end
