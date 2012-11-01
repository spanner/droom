class DocumentLinks < ActiveRecord::Migration
  def change
    create_table :droom_document_links do |t|
      t.integer :person_id
      t.integer :document_attachment_id
      t.timestamps
    end
    add_index :droom_document_links, :person_id
    add_index :droom_document_links, :document_attachment_id
    
    add_column :droom_personal_documents, :document_link_id, :integer
    add_index :droom_personal_documents, :document_link_id
  end
end
