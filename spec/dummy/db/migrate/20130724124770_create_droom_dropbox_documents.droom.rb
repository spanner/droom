# This migration comes from droom (originally 20130308103807)
class CreateDroomDropboxDocuments < ActiveRecord::Migration
  def change
    create_table :droom_dropbox_documents do |t|
      t.integer :person_id
      t.string  :path
      t.integer :document_id
      t.boolean :deleted
      t.timestamps
    end
  end
end
