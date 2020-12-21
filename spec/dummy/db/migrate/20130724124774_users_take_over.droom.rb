# This migration comes from droom (originally 20130627071938)
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

  end
end
