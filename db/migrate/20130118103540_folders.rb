class Folders < ActiveRecord::Migration
  def change
    create_table :droom_folders do |t|
      t.string :name
      t.integer :parent_id
      t.string :holder_type
      t.string :holder_id
      t.integer :created_by_id
      t.timestamps
    end
    
    create_table :droom_personal_folders do |t|
      t.integer :folder_id
      t.integer :person_id
      t.timestamps
    end

    add_column :documents, :folder_id
    add_index :documents, :folder_id

    drop_table :document_links
    drop_table :document_attachments
      
  end
end
