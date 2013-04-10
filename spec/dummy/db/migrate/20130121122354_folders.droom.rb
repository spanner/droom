# This migration comes from droom (originally 20130118103540)
class Folders < ActiveRecord::Migration
  def change
    create_table :droom_folders do |t|
      t.string :slug
      t.string :holder_type
      t.string :holder_id
      t.string :ancestry
      t.boolean :public, :default => 0
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_folders, :ancestry
    
    create_table :droom_personal_folders do |t|
      t.integer :folder_id
      t.integer :person_id
      t.timestamps
    end

    add_column :droom_documents, :folder_id, :integer
    add_index :droom_documents, :folder_id

    add_column :droom_personal_documents, :personal_folder_id, :integer
    add_index :droom_personal_documents, :personal_folder_id

    # folders will be lazy-loaded when they are needed, so:
    #   transmute document-attachments into document->folder->holder associations
    #   taking care to create agenda_category buckets as required.
    
    # Droom::DocumentAttachment.all.each do |da|
    #   if da.category
    #     da.attachee.find_or_create_agenda_category(da.category).receive_document(da.document)
    #   else
    #     da.attachee.receive_document da.document
    #   end
    # end
    # 
    # #   trigger the creation of personal folders from invitations and memberships
    # 
    # Droom::Invitation.all.map(&:link_folder)
    # Droom::Membership.all.map(&:link_folder)

    # drop_table :document_links
    # drop_table :document_attachments
  end
  
end
