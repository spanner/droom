# This migration comes from droom (originally 20130121140158)
class GiveDocumentsExtractedText < ActiveRecord::Migration
  def change
    add_column :droom_documents, :extracted_text, :text
  end
end
