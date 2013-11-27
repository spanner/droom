# This migration comes from droom (originally 20130226092944)
class GiveScrapsDocument < ActiveRecord::Migration
  def up
    add_column :droom_scraps, :document_id, :integer
  end
end
