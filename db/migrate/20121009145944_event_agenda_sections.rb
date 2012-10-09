class EventAgendaSections < ActiveRecord::Migration
  def change
    remove_column :droom_agenda_sections, :event_id
    rename_table :droom_agenda_sections, :droom_categories
    rename_column :droom_document_attachments, :agenda_section_id, :category_id
    create_table :droom_agenda_categories do |t|
      t.integer :event_id
      t.integer :category_id
      t.integer :created_by_id
      t.timestamps
    end
  end
end
