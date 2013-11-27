# This migration comes from droom (originally 20130228134143)
class StoreMetadata < ActiveRecord::Migration
  def change
    add_column :droom_documents, :extracted_metadata, :text
  end
end
