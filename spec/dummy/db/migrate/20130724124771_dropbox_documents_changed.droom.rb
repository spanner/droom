# This migration comes from droom (originally 20130308154552)
class DropboxDocumentsChanged < ActiveRecord::Migration
  def change
    rename_column :droom_dropbox_documents, :deleted, :modified
  end
end
