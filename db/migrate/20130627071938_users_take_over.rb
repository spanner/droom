class UsersTakeOver < ActiveRecord::Migration
  def change
    add_column :droom_invitations, :user_id, :integer
    add_column :droom_memberships, :user_id, :integer
    add_column :droom_personal_folders, :user_id, :integer
    add_column :droom_dropbox_documents, :user_id, :integer

    add_index :droom_invitations, :user_id
    add_index :droom_memberships, :user_id
    add_index :droom_personal_folders, :user_id
    add_index :droom_dropbox_documents, :user_id

    user_ids_by_person = Droom::Person.all.each_with_object({}) do |person, carrier|
      carrier[person.id] = person.user.id if person.user
    end

    Droom::Invitation.reset_column_information
    Droom::Invitation.all.each do |inv|
      inv.update_column :user_id, user_ids_by_person[inv.person_id]
    end

    Droom::Membership.reset_column_information
    Droom::Membership.all.each do |mem|
      mem.update_column :user_id, user_ids_by_person[mem.person_id]
    end

    Droom::PersonalFolder.reset_column_information
    Droom::PersonalFolder.all.each do |pf|
      pf.update_column :user_id, user_ids_by_person[pf.person_id]
    end

    Droom::DropboxDocument.reset_column_information
    Droom::DropboxDocument.all.each do |dd|
      dd.update_column :user_id, user_ids_by_person[dd.person_id]
    end

  end
end
