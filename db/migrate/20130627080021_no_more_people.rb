class NoMorePeople < ActiveRecord::Migration
  def change
    remove_column :droom_invitations, :person_id
    remove_column :droom_memberships, :person_id
    remove_column :droom_personal_folders, :person_id
    remove_column :droom_dropbox_documents, :person_id
    
    drop_table :droom_people
    drop_table :droom_personal_documents
  end
end
