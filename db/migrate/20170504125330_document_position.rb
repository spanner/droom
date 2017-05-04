class DocumentPosition < ActiveRecord::Migration
  def change
    add_column :droom_documents, :position, :integer, default: 1
  end
end
