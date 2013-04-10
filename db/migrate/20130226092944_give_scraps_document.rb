class GiveScrapsDocument < ActiveRecord::Migration
  def up
    add_column :droom_scraps, :document_id, :integer
  end
end
