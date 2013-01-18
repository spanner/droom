class Folders < ActiveRecord::Migration
  def change
    create_table :droom_folders do |t|
      t.string :slug
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

    add_column :droom_documents, :folder_id, :integer
    add_index :droom_documents, :folder_id

    add_column :droom_personal_documents, :personal_folder_id, :integer
    add_index :droom_personal_documents, :personal_folder_id

    # call all events and agenda sections to cause their folders to be created
    # transmute document attachments into document folder associations
    # add a folder to each group
    # discard personal documents and document links?
    # transmute document-group associations into document-folder associations
    # trigger creation of personal folders
    # which should trigger the recreation of personal documents
    
    # -> person-folders can be pushed to dropbox and/or DAV filing.

    # drop_table :document_links
    # drop_table :document_attachments
  end
end
