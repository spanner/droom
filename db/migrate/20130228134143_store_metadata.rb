class StoreMetadata < ActiveRecord::Migration
  def change
    add_column :droom_documents, :extracted_metadata, :text
  end
end
